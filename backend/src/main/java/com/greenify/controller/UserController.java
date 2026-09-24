package com.greenify.controller;

import com.greenify.dto.wallet.WithdrawRequest;
import com.greenify.entity.DepositSession;
import com.greenify.entity.User;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.PlasticDepositRepository;
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

    @GetMapping("/me/transactions")
    public ResponseEntity<?> getTransactions(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(walletService.getUserTransactionHistory(principal.getUserId()));
    }

    @PostMapping("/me/withdraw")
    public ResponseEntity<?> withdrawToBkash(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody WithdrawRequest request) {
        return ResponseEntity.ok(walletService.withdrawToBkash(principal.getUserId(), request, idempotencyKey));
    }

    @GetMapping("/coupons")
    public ResponseEntity<?> getCoupons() {
        return ResponseEntity.ok(couponService.getAllAvailableCoupons());
    }

    @PostMapping("/coupons/{couponId}/redeem")
    public ResponseEntity<?> redeemCoupon(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long couponId) {
        return ResponseEntity.ok(couponService.redeemCoupon(principal.getUserId(), couponId));
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
