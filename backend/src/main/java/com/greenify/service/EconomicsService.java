package com.greenify.service;

import com.greenify.repository.SystemConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
@RequiredArgsConstructor
public class EconomicsService {

    private final SystemConfigRepository configRepository;

    @Value("${economics.tokens-per-kg:100}")
    private int defaultTokensPerKg;

    @Value("${economics.tokens-per-taka:4}")
    private int defaultTokensPerTaka;

    @Value("${economics.min-withdrawal-taka:100}")
    private int defaultMinWithdrawalTaka;

    public int getTokensPerKg() {
        return configRepository.findById("tokens_per_kg")
                .map(c -> Integer.parseInt(c.getConfigValue()))
                .orElse(defaultTokensPerKg);
    }

    public int getTokensPerTaka() {
        return configRepository.findById("tokens_per_taka")
                .map(c -> Integer.parseInt(c.getConfigValue()))
                .orElse(defaultTokensPerTaka);
    }

    public int getMinWithdrawalTaka() {
        return configRepository.findById("min_withdrawal_taka")
                .map(c -> Integer.parseInt(c.getConfigValue()))
                .orElse(defaultMinWithdrawalTaka);
    }

    public int getMinWithdrawalTokens() {
        return getMinWithdrawalTaka() * getTokensPerTaka();
    }

    /**
     * Calculates tokens earned from plastic weight in kg.
     * Rule: 100 tokens per kg -> floor(weight_kg * 100). Grams under 10g are discarded.
     */
    public int calculateTokensEarned(BigDecimal weightKg) {
        if (weightKg == null || weightKg.compareTo(BigDecimal.ZERO) <= 0) {
            return 0;
        }
        BigDecimal rate = BigDecimal.valueOf(getTokensPerKg());
        return weightKg.multiply(rate).setScale(0, RoundingMode.FLOOR).intValue();
    }

    /**
     * Converts token amount to BDT Taka cashback.
     * Rule: 4 tokens = ৳1.00 BDT
     */
    public BigDecimal calculateCashbackTaka(int tokens) {
        if (tokens <= 0) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        return BigDecimal.valueOf(tokens)
                .divide(BigDecimal.valueOf(getTokensPerTaka()), 2, RoundingMode.HALF_UP);
    }

    /**
     * Validates if token withdrawal meets platform constraints:
     * 1. Must be a multiple of tokens_per_taka (default 4).
     * 2. Must meet minimum withdrawal threshold (default 400 tokens / ৳100).
     */
    public boolean isValidWithdrawal(int tokens) {
        int tokensPerTaka = getTokensPerTaka();
        int minTokens = getMinWithdrawalTokens();
        return tokens >= minTokens && (tokens % tokensPerTaka == 0);
    }
}
