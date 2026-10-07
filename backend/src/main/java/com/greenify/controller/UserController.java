package com.greenify.controller;

import com.greenify.dto.wallet.WithdrawRequest;
import com.greenify.entity.DepositSession;
import com.greenify.entity.User;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.PlasticDepositRepository;
import com.greenify.repository.SmartBoothRepository;
import com.greenify.repository.UserRepository;
import com.greenify.security.UserPrincipal;
import com.greenify.service.CouponService;
import com.greenify.service.DepositService;
import com.greenify.service.WalletService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final PlasticDepositRepository depositRepository;
    private final WalletService walletService;
    private final CouponService couponService;
    private final DepositService depositService;

    @GetMapping("/me")
    public ResponseEntity<User> getProfile(@AuthenticationPrincipal UserPrincipal principal) {
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found."));
        return ResponseEntity.ok(user);
    }

    @GetMapping("/me/dashboard")
    public ResponseEntity<?> getUserDashboard(@AuthenticationPrincipal UserPrincipal principal) {
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found."));

        BigDecimal totalWeightKg = depositRepository.getTotalWeightKgByUserId(user.getUserId());
        long depositCount = depositRepository.findByUserUserIdOrderByDepositTimestampDesc(user.getUserId()).size();
        BigDecimal co2PreventedKg = totalWeightKg.multiply(BigDecimal.valueOf(1.5));

        return ResponseEntity.ok(Map.of(
                "userId", user.getUserId(),
                "fullName", user.getFullName(),
                "phoneNumber", user.getPhoneNumber(),
                "bkashNumber", user.getBkashNumber() != null ? user.getBkashNumber() : "",
                "totalTokens", user.getTotalTokens(),
                "walletBalanceTaka", user.getWalletBalance(),
                "loyaltyLevel", user.getLoyaltyLevel(),
                "totalPlasticKg", totalWeightKg,
                "totalDeposits", depositCount,
                "co2PreventedKg", co2PreventedKg
        ));
    }

    private final com.greenify.service.GeminiService geminiService;

    @GetMapping("/me/ai/advice")
    public ResponseEntity<?> getCitizenAdvice(@AuthenticationPrincipal UserPrincipal principal) {
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found."));
        BigDecimal totalWeightKg = depositRepository.getTotalWeightKgByUserId(user.getUserId());
        return ResponseEntity.ok(geminiService.getCitizenEcoAdvice(
                user.getFullName(),
                totalWeightKg,
                user.getTotalTokens(),
                user.getLoyaltyLevel() != null ? user.getLoyaltyLevel() : "Eco Buddy"
        ));
    }

    @GetMapping("/me/transactions")
    public ResponseEntity<?> getTransactions(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(walletService.getUserTransactionHistory(principal.getUserId()));
    }

    @PostMapping("/me/withdraw")
    public ResponseEntity<?> withdrawToBkash(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody WithdrawRequest request) {
        var tx = walletService.withdrawToBkash(principal.getUserId(), request, idempotencyKey);
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found."));
        return ResponseEntity.ok(Map.of(
                "transactionId", tx.getTransactionId(),
                "transactionType", tx.getTransactionType(),
                "tokensDeducted", request.getTokens(),
                "cashDelta", tx.getCashDelta(),
                "totalTokens", user.getTotalTokens(),
                "walletBalanceTaka", user.getWalletBalance(),
                "status", tx.getStatus(),
                "bkashTrxId", tx.getBkashTrxId() != null ? tx.getBkashTrxId() : "",
                "success", "Completed".equalsIgnoreCase(tx.getStatus())
        ));
    }

    @GetMapping("/coupons")
    public ResponseEntity<?> getCoupons() {
        return ResponseEntity.ok(couponService.getAllAvailableCoupons());
    }

    @PostMapping("/coupons/{couponId}/redeem")
    public ResponseEntity<?> redeemCoupon(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long couponId) {
        var redemption = couponService.redeemCoupon(principal.getUserId(), couponId);
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User profile not found."));
        return ResponseEntity.ok(Map.of(
                "redemptionId", redemption.getRedemptionId(),
                "couponId", couponId,
                "promoCode", redemption.getCoupon().getPromoCode(),
                "discountPercentage", redemption.getCoupon().getDiscountPercentage(),
                "brandName", redemption.getCoupon().getBrandName(),
                "totalTokens", user.getTotalTokens(),
                "walletBalanceTaka", user.getWalletBalance(),
                "success", true
        ));
    }

    private final SmartBoothRepository boothRepository;
    private final com.greenify.service.EconomicsService economicsService;

    @GetMapping("/economics")
    public ResponseEntity<?> getEconomics() {
        return ResponseEntity.ok(Map.of(
                "tokensPerKg", economicsService.getTokensPerKg(),
                "tokensPerTaka", economicsService.getTokensPerTaka(),
                "minWithdrawalTaka", economicsService.getMinWithdrawalTaka(),
                "co2KgPerPlasticKg", economicsService.getCo2KgPerPlasticKg()
        ));
    }

    @GetMapping("/booths")
    public ResponseEntity<?> getBooths() {
        return ResponseEntity.ok(boothRepository.findAll());
    }

    @GetMapping("/leaderboard")
    public ResponseEntity<?> getLeaderboard() {
        var topUsers = userRepository.findAll().stream()
                .filter(u -> u.getRole() == com.greenify.domain.enums.Role.USER)
                .sorted((a, b) -> Integer.compare(b.getTotalTokens(), a.getTotalTokens()))
                .limit(25)
                .map(u -> Map.of(
                        "userId", u.getUserId(),
                        "fullName", u.getFullName(),
                        "totalTokens", u.getTotalTokens(),
                        "walletBalanceTaka", u.getWalletBalance(),
                        "totalPlasticKg", depositRepository.getTotalWeightKgByUserId(u.getUserId()),
                        "loyaltyLevel", u.getLoyaltyLevel() != null ? u.getLoyaltyLevel() : "Eco Buddy"
                ))
                .toList();
        return ResponseEntity.ok(topUsers);
    }

    @PostMapping("/me/deposit/manual")
    public ResponseEntity<?> manualDeposit(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody Map<String, Object> body) {
        BigDecimal weightKg = new BigDecimal(body.get("weightKg").toString());
        String plasticType = body.containsKey("plasticType") ? body.get("plasticType").toString() : "PET Plastic Bottles";
        Long boothId = body.containsKey("boothId") && body.get("boothId") != null
                ? Long.parseLong(body.get("boothId").toString())
                : null;

        var deposit = depositService.manualDeposit(principal.getUserId(), boothId, weightKg, plasticType);
        User user = userRepository.findById(principal.getUserId()).orElseThrow();
        return ResponseEntity.ok(Map.of(
                "depositId", deposit.getDepositId(),
                "plasticWeightKg", deposit.getPlasticWeightKg(),
                "plasticType", deposit.getPlasticType(),
                "tokensEarned", deposit.getTokensEarned(),
                "totalTokens", user.getTotalTokens(),
                "walletBalanceTaka", user.getWalletBalance(),
                "success", true
        ));
    }

    @PostMapping("/deposit-sessions")
    public ResponseEntity<DepositSession> createDepositSession(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody Map<String, String> body) {
        Long boothId = Long.parseLong(body.get("boothId"));
        String qrToken = body.get("qrToken");
        return ResponseEntity.ok(depositService.createDepositSession(principal.getUserId(), boothId, qrToken));
    }
}
