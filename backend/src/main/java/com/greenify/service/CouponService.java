package com.greenify.service;

import com.greenify.domain.enums.TxType;
import com.greenify.entity.Coupon;
import com.greenify.entity.User;
import com.greenify.entity.UserCouponRedemption;
import com.greenify.entity.WalletTransaction;
import com.greenify.exception.BadRequestException;
import com.greenify.exception.InsufficientBalanceException;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.CouponRepository;
import com.greenify.repository.UserCouponRedemptionRepository;
import com.greenify.repository.UserRepository;
import com.greenify.repository.WalletTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CouponService {

    private final CouponRepository couponRepository;
    private final UserRepository userRepository;
    private final UserCouponRedemptionRepository redemptionRepository;
    private final WalletTransactionRepository transactionRepository;

    public List<Coupon> getAllAvailableCoupons() {
        return couponRepository.findAll();
    }

    public List<UserCouponRedemption> getUserRedemptions(Long userId) {
        return redemptionRepository.findByUserUserIdOrderByRedeemedAtDesc(userId);
    }

    @Transactional
    public UserCouponRedemption redeemCoupon(Long userId, Long couponId) {
        Coupon coupon = couponRepository.findByIdWithLock(couponId)
                .orElseThrow(() -> new ResourceNotFoundException("Coupon not found: " + couponId));

        if (coupon.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Coupon has expired.");
        }

        if (coupon.getQuantityAvailable() <= 0) {
            throw new BadRequestException("Coupon is out of stock.");
        }

        User user = userRepository.findByIdWithLock(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        if (user.getTotalTokens() < coupon.getTokenCost()) {
            throw new InsufficientBalanceException("Insufficient token balance. Requires " +
                    coupon.getTokenCost() + " tokens.");
        }

        // 1. Deduct user tokens
        int updatedBalance = user.getTotalTokens() - coupon.getTokenCost();
        user.setTotalTokens(updatedBalance);
        userRepository.save(user);

        // 2. Decrement coupon quantity
        coupon.setQuantityAvailable(coupon.getQuantityAvailable() - 1);
        couponRepository.save(coupon);

        // 3. Record redemption
        UserCouponRedemption redemption = UserCouponRedemption.builder()
                .user(user)
                .coupon(coupon)
                .build();
        redemption = redemptionRepository.save(redemption);

        // 4. Record ledger transaction
        WalletTransaction tx = WalletTransaction.builder()
                .user(user)
                .transactionType(TxType.COUPON_PURCHASE.getDisplayName())
                .tokensDelta(-coupon.getTokenCost())
                .cashDelta(BigDecimal.ZERO)
                .balanceAfterTokens(updatedBalance)
                .status("Completed")
                .build();
        transactionRepository.save(tx);

        log.info("User ID {} successfully redeemed coupon {} (Promo: {})", userId, couponId, coupon.getPromoCode());
        return redemption;
    }
}
