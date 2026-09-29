package com.greenify.service;

import com.greenify.domain.enums.TxType;
import com.greenify.dto.wallet.WithdrawRequest;
import com.greenify.entity.User;
import com.greenify.entity.WalletTransaction;
import com.greenify.exception.BadRequestException;
import com.greenify.exception.InsufficientBalanceException;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.UserRepository;
import com.greenify.repository.WalletTransactionRepository;
import com.greenify.service.payout.PayoutGateway;
import com.greenify.service.payout.PayoutResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class WalletService {

    private final UserRepository userRepository;
    private final WalletTransactionRepository walletTransactionRepository;
    private final EconomicsService economicsService;
    private final PayoutGateway payoutGateway;

    @Transactional
    public WalletTransaction withdrawToBkash(Long userId, WithdrawRequest request, String idempotencyKey) {
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            Optional<WalletTransaction> existingTx = walletTransactionRepository.findByIdempotencyKey(idempotencyKey);
            if (existingTx.isPresent()) {
                log.info("Idempotency key match found: {}. Returning cached transaction result.", idempotencyKey);
                return existingTx.get();
            }
        }

        if (!economicsService.isValidWithdrawal(request.getTokens())) {
            throw new BadRequestException("Invalid withdrawal token amount. Must be a multiple of " +
                    economicsService.getTokensPerTaka() + " tokens and at least " +
                    economicsService.getMinWithdrawalTokens() + " tokens (৳" +
                    economicsService.getMinWithdrawalTaka() + " BDT).");
        }

        // Row lock user for atomic balance check and debit
        User user = userRepository.findByIdWithLock(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        if (user.getTotalTokens() < request.getTokens()) {
            throw new InsufficientBalanceException("Insufficient token balance. Current balance: " +
                    user.getTotalTokens() + " tokens.");
        }

        BigDecimal cashTaka = economicsService.calculateCashbackTaka(request.getTokens());

        // Update bKash number on user profile if not set
        if (user.getBkashNumber() == null || user.getBkashNumber().isBlank()) {
            user.setBkashNumber(request.getBkashNumber());
        }

        // Deduct tokens atomically
        int updatedBalance = user.getTotalTokens() - request.getTokens();
        user.setTotalTokens(updatedBalance);
        userRepository.save(user);

        // Record pending transaction ledger
        WalletTransaction transaction = WalletTransaction.builder()
                .user(user)
                .transactionType(TxType.CASHBACK_WITHDRAWAL.getDisplayName())
                .tokensDelta(-request.getTokens())
                .cashDelta(cashTaka)
                .balanceAfterTokens(updatedBalance)
                .status("Pending")
                .idempotencyKey(idempotencyKey)
                .build();

        transaction = walletTransactionRepository.save(transaction);

        // Execute payout through gateway
        PayoutResult payoutResult = payoutGateway.sendPayout(request.getBkashNumber(), cashTaka, "WITHDRAW-" + transaction.getTransactionId());

        if (payoutResult.isSuccess()) {
            transaction.setStatus("Completed");
            transaction.setBkashTrxId(payoutResult.getTransactionId());
            log.info("Withdrawal of {} tokens (৳{}) completed for user ID {}. TrxId: {}",
                    request.getTokens(), cashTaka, userId, payoutResult.getTransactionId());
        } else {
            // Rollback token debit on payout failure
            user.setTotalTokens(user.getTotalTokens() + request.getTokens());
            userRepository.save(user);

            transaction.setStatus("Failed");
            log.warn("Withdrawal payout failed for user ID {}: {}. Token debit rolled back.",
                    userId, payoutResult.getErrorMessage());
        }

        return walletTransactionRepository.save(transaction);
    }

    public List<WalletTransaction> getUserTransactionHistory(Long userId) {
        return walletTransactionRepository.findByUserUserIdOrderByTransactionTimestampDesc(userId);
    }
}
