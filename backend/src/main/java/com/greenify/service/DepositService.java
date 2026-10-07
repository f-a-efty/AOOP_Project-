package com.greenify.service;

import com.greenify.domain.enums.TxType;
import com.greenify.entity.*;
import com.greenify.exception.BadRequestException;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DepositService {

    private final SmartBoothRepository boothRepository;
    private final DepositSessionRepository sessionRepository;
    private final PlasticDepositRepository depositRepository;
    private final UserRepository userRepository;
    private final WalletTransactionRepository transactionRepository;
    private final PickupRequestRepository pickupRequestRepository;
    private final com.greenify.repository.RecyclingCompanyRepository companyRepository;
    private final com.greenify.repository.NotificationRepository notificationRepository;
    private final EconomicsService economicsService;
    private final PasswordEncoder passwordEncoder;

    @Value("${economics.qr-ttl-seconds:60}")
    private int qrTtlSeconds;

    @Value("${economics.almost-full-threshold-pct:80}")
    private int almostFullThresholdPct;

    @Transactional
    public String generateBoothQrToken(Long boothId) {
        SmartBooth booth = boothRepository.findById(boothId)
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + boothId));

        if ("Under Maintenance".equalsIgnoreCase(booth.getBoothStatus()) || "Full".equalsIgnoreCase(booth.getBoothStatus())) {
            throw new BadRequestException("Booth is currently unavailable for deposits (Status: " + booth.getBoothStatus() + ").");
        }

        String rawToken = UUID.randomUUID().toString();
        log.info("Generated new dynamic QR token for Booth {}: {}", booth.getBoothCode(), rawToken);
        return rawToken;
    }

    @Transactional
    public DepositSession createDepositSession(Long userId, Long boothId, String qrToken) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        SmartBooth booth = boothRepository.findById(boothId)
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + boothId));

        String sessionId = "DS-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        DepositSession session = DepositSession.builder()
                .sessionId(sessionId)
                .user(user)
                .booth(booth)
                .qrTokenHash(passwordEncoder.encode(qrToken))
                .expiresAt(LocalDateTime.now().plusSeconds(qrTtlSeconds))
                .status("PENDING")
                .build();

        return sessionRepository.save(session);
    }

    @Transactional
    public PlasticDeposit submitPlasticWeight(Long boothId, String sessionId, BigDecimal weightKg, String plasticType) {
        DepositSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Deposit session not found: " + sessionId));

        if ("COMPLETED".equalsIgnoreCase(session.getStatus())) {
            throw new BadRequestException("Deposit session has already been completed.");
        }

        if (session.getExpiresAt().isBefore(LocalDateTime.now())) {
            session.setStatus("EXPIRED");
            sessionRepository.save(session);
            throw new BadRequestException("Deposit session QR code has expired.");
        }

        // Lock booth row
        SmartBooth booth = boothRepository.findByIdWithLock(boothId)
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + boothId));

        BigDecimal availableCapacity = booth.getCapacityKg().subtract(booth.getCurrentWeightKg());
        if (weightKg.compareTo(availableCapacity) > 0) {
            throw new BadRequestException("Submitted weight (" + weightKg + " kg) exceeds remaining booth capacity (" + availableCapacity + " kg).");
        }

        User user = userRepository.findByIdWithLock(session.getUser().getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + session.getUser().getUserId()));

        // Calculate tokens
        int tokensEarned = economicsService.calculateTokensEarned(weightKg);

        // Update booth weight and status
        BigDecimal newBoothWeight = booth.getCurrentWeightKg().add(weightKg);
        booth.setCurrentWeightKg(newBoothWeight);

        BigDecimal fillPct = newBoothWeight.divide(booth.getCapacityKg(), 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
        String newStatus = "Available";
        if (fillPct.compareTo(BigDecimal.valueOf(100)) >= 0) {
            newStatus = "Full";
        } else if (fillPct.compareTo(BigDecimal.valueOf(almostFullThresholdPct)) >= 0) {
            newStatus = "Almost Full";
        }
        booth.setBoothStatus(newStatus);
        boothRepository.save(booth);

        // Create plastic deposit record
        PlasticDeposit deposit = PlasticDeposit.builder()
                .user(user)
                .booth(booth)
                .session(session)
                .plasticWeightKg(weightKg)
                .plasticType(plasticType != null ? plasticType : "PET/Mix")
                .tokensEarned(tokensEarned)
                .rateSnapshot(economicsService.getTokensPerKg())
                .build();

        deposit = depositRepository.save(deposit);

        // Credit tokens to user
        int newBalance = user.getTotalTokens() + tokensEarned;
        user.setTotalTokens(newBalance);

        // Recompute loyalty tier
        updateUserLoyaltyTier(user);
        userRepository.save(user);

        // Append to ledger
        WalletTransaction tx = WalletTransaction.builder()
                .user(user)
                .transactionType(TxType.DEPOSIT_CREDIT.getDisplayName())
                .tokensDelta(tokensEarned)
                .cashDelta(BigDecimal.ZERO)
                .balanceAfterTokens(newBalance)
                .status("Completed")
                .build();

        transactionRepository.save(tx);

        // Complete session
        session.setStatus("COMPLETED");
        sessionRepository.save(session);

        // Auto-trigger pickup request if Almost Full or Full and no active pickup request exists
        if ("Almost Full".equalsIgnoreCase(newStatus) || "Full".equalsIgnoreCase(newStatus)) {
            triggerAutomatedPickupRequest(booth, newStatus);
        }

        log.info("Successfully processed deposit of {} kg ({} tokens) for User ID {} at Booth {}.",
                weightKg, tokensEarned, user.getUserId(), booth.getBoothCode());

        return deposit;
    }

    private void updateUserLoyaltyTier(User user) {
        BigDecimal totalKg = depositRepository.getTotalWeightKgByUserId(user.getUserId());
        if (totalKg.compareTo(BigDecimal.valueOf(300)) >= 0) {
            user.setLoyaltyLevel("Nature Guardian");
        } else if (totalKg.compareTo(BigDecimal.valueOf(150)) >= 0) {
            user.setLoyaltyLevel("Nature Hero");
        } else if (totalKg.compareTo(BigDecimal.valueOf(50)) >= 0) {
            user.setLoyaltyLevel("Green Friend");
        } else {
            user.setLoyaltyLevel("Eco Buddy");
        }
    }

    private void triggerAutomatedPickupRequest(SmartBooth booth, String boothStatus) {
        boolean exists = pickupRequestRepository.findByBoothBoothIdAndStatusIn(
                booth.getBoothId(), java.util.Arrays.asList("Pending", "Accepted", "Vehicle Assigned", "On Pickup")
        ).isPresent();

        if (!exists) {
            com.greenify.entity.RecyclingCompany company = booth.getCompany();
            if (company == null) {
                company = companyRepository.findAll().stream().findFirst().orElse(null);
                if (company != null) {
                    booth.setCompany(company);
                    boothRepository.save(booth);
                }
            }

            String priority = "Full".equalsIgnoreCase(boothStatus) ? "HIGH" : "NORMAL";
            String requestCode = "REQ-" + booth.getBoothCode().replace("BTH-", "") + "-" + UUID.randomUUID().toString().substring(0, 4).toUpperCase();

            PickupRequest request = PickupRequest.builder()
                    .requestCode(requestCode)
                    .booth(booth)
                    .company(company)
                    .priority(priority)
                    .status("Pending")
                    .payloadKgAtRequest(booth.getCurrentWeightKg() != null ? booth.getCurrentWeightKg() : BigDecimal.ZERO)
                    .build();

            pickupRequestRepository.save(request);
            log.info("Auto-generated pickup request {} for Booth {} (Priority: {})", requestCode, booth.getBoothCode(), priority);

            if (company != null) {
                notificationRepository.save(com.greenify.entity.Notification.builder()
                        .recipientRole("COMPANY")
                        .recipientId(company.getCompanyId())
                        .title("Smart Booth Fill Alert: " + booth.getBoothCode())
                        .message(String.format("Smart Booth %s at %s has reached %s capacity (%.1f kg). Pickup dispatch recommended.",
                                booth.getBoothCode(), booth.getLocationAddress(), boothStatus,
                                booth.getCurrentWeightKg() != null ? booth.getCurrentWeightKg().doubleValue() : 0.0))
                        .category("Booth Full")
                        .isRead(false)
                        .build());
            }
        }
    }

    @Transactional
    public PlasticDeposit manualDeposit(Long userId, Long boothId, BigDecimal weightKg, String plasticType) {
        if (boothId == null) {
            boothId = boothRepository.findAll().stream().findFirst()
                    .map(SmartBooth::getBoothId).orElse(1L);
        }
        return directSimulatedDeposit(boothId, userId, weightKg, plasticType);
    }

    @Transactional
    public PlasticDeposit directSimulatedDeposit(Long boothId, Long userId, BigDecimal weightKg, String plasticType) {
        User user = (userId != null)
                ? userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId))
                : userRepository.findAll().stream().filter(u -> u.getRole() == com.greenify.domain.enums.Role.USER).findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("No citizen user found in system."));

        SmartBooth booth = boothRepository.findByIdWithLock(boothId)
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + boothId));

        String sessionId = "SIM-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        DepositSession session = DepositSession.builder()
                .sessionId(sessionId)
                .user(user)
                .booth(booth)
                .qrTokenHash("SIMULATED_TOKEN")
                .expiresAt(LocalDateTime.now().plusHours(1))
                .status("COMPLETED")
                .build();
        session = sessionRepository.save(session);

        int tokensEarned = economicsService.calculateTokensEarned(weightKg);

        BigDecimal newBoothWeight = booth.getCurrentWeightKg().add(weightKg);
        booth.setCurrentWeightKg(newBoothWeight);

        BigDecimal fillPct = newBoothWeight.divide(booth.getCapacityKg(), 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
        String newStatus = "Available";
        if (fillPct.compareTo(BigDecimal.valueOf(100)) >= 0) {
            newStatus = "Full";
        } else if (fillPct.compareTo(BigDecimal.valueOf(almostFullThresholdPct)) >= 0) {
            newStatus = "Almost Full";
        }
        booth.setBoothStatus(newStatus);
        boothRepository.save(booth);

        PlasticDeposit deposit = PlasticDeposit.builder()
                .user(user)
                .booth(booth)
                .session(session)
                .plasticWeightKg(weightKg)
                .plasticType(plasticType != null ? plasticType : "PET/Mix")
                .tokensEarned(tokensEarned)
                .rateSnapshot(economicsService.getTokensPerKg())
                .build();
        deposit = depositRepository.save(deposit);

        int newBalance = user.getTotalTokens() + tokensEarned;
        user.setTotalTokens(newBalance);
        updateUserLoyaltyTier(user);
        userRepository.save(user);

        WalletTransaction tx = WalletTransaction.builder()
                .user(user)
                .transactionType(TxType.DEPOSIT_CREDIT.getDisplayName())
                .tokensDelta(tokensEarned)
                .cashDelta(BigDecimal.ZERO)
                .balanceAfterTokens(newBalance)
                .status("Completed")
                .build();
        transactionRepository.save(tx);

        if ("Almost Full".equalsIgnoreCase(newStatus) || "Full".equalsIgnoreCase(newStatus)) {
            triggerAutomatedPickupRequest(booth, newStatus);
        }

        log.info("Direct simulator deposit processed: {} kg at Booth {} for User {}.", weightKg, booth.getBoothCode(), user.getFullName());
        return deposit;
    }

    @Transactional
    public SmartBooth setBoothFillPercentage(Long boothId, double fillPercentage) {
        SmartBooth booth = boothRepository.findByIdWithLock(boothId)
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + boothId));

        double clampedPct = Math.max(0.0, Math.min(100.0, fillPercentage));
        BigDecimal capacity = booth.getCapacityKg() != null ? booth.getCapacityKg() : BigDecimal.valueOf(100.0);
        BigDecimal newWeight = capacity.multiply(BigDecimal.valueOf(clampedPct / 100.0)).setScale(2, RoundingMode.HALF_UP);

        booth.setCurrentWeightKg(newWeight);
        String newStatus = "Available";
        if (clampedPct >= 100.0) {
            newStatus = "Full";
        } else if (clampedPct >= 80.0) {
            newStatus = "Almost Full";
        }
        booth.setBoothStatus(newStatus);
        SmartBooth saved = boothRepository.save(booth);

        if (clampedPct >= 80.0) {
            triggerAutomatedPickupRequest(booth, newStatus);
        }
        log.info("Simulator set booth {} fill to {}% ({} kg). Status: {}", booth.getBoothCode(), clampedPct, newWeight, newStatus);
        return saved;
    }

    @Transactional
    public SmartBooth emptyBooth(Long boothId) {
        SmartBooth booth = boothRepository.findByIdWithLock(boothId)
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + boothId));

        booth.setCurrentWeightKg(BigDecimal.ZERO);
        booth.setBoothStatus("Available");
        return boothRepository.save(booth);
    }
}
