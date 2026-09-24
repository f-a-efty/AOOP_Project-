package com.greenify;

import com.greenify.repository.SystemConfigRepository;
import com.greenify.service.EconomicsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class EconomicsServiceTest {

    @Mock
    private SystemConfigRepository configRepository;

    private EconomicsService economicsService;

    @BeforeEach
    void setUp() {
        economicsService = new EconomicsService(configRepository);
    }

    @Test
    @DisplayName("Deposit 1.000 kg yields 100 tokens")
    void testDeposit1kg() {
        BigDecimal weight = new BigDecimal("1.000");
        int tokens = economicsService.calculateTokensEarned(weight);
        assertEquals(100, tokens);
        assertEquals(new BigDecimal("25.00"), economicsService.calculateCashbackTaka(tokens));
        assertFalse(economicsService.isValidWithdrawal(tokens), "100 tokens is below ৳100 minimum withdrawal");
    }

    @Test
    @DisplayName("Deposit 1.500 kg yields 150 tokens")
    void testDeposit1_5kg() {
        BigDecimal weight = new BigDecimal("1.500");
        int tokens = economicsService.calculateTokensEarned(weight);
        assertEquals(150, tokens);
        assertEquals(new BigDecimal("37.50"), economicsService.calculateCashbackTaka(tokens));
        assertFalse(economicsService.isValidWithdrawal(tokens), "150 tokens is below ৳100 minimum withdrawal");
    }

    @Test
    @DisplayName("Deposit 4.000 kg yields 400 tokens (৳100.00 BDT) and allows withdrawal")
    void testDeposit4kg() {
        BigDecimal weight = new BigDecimal("4.000");
        int tokens = economicsService.calculateTokensEarned(weight);
        assertEquals(400, tokens);
        assertEquals(new BigDecimal("100.00"), economicsService.calculateCashbackTaka(tokens));
        assertTrue(economicsService.isValidWithdrawal(tokens), "400 tokens (৳100) is valid for withdrawal");
    }

    @Test
    @DisplayName("Deposit 0.250 kg yields 25 tokens")
    void testDepositQuarterKg() {
        BigDecimal weight = new BigDecimal("0.250");
        int tokens = economicsService.calculateTokensEarned(weight);
        assertEquals(25, tokens);
        assertEquals(new BigDecimal("6.25"), economicsService.calculateCashbackTaka(tokens));
    }

    @Test
    @DisplayName("Deposit 0.009 kg yields 0 tokens (remainder under 10g discarded)")
    void testDepositUnder10g() {
        BigDecimal weight = new BigDecimal("0.009");
        int tokens = economicsService.calculateTokensEarned(weight);
        assertEquals(0, tokens);
    }

    @Test
    @DisplayName("Withdraw 402 tokens rejected (not a multiple of 4)")
    void testWithdrawNonMultipleOfFour() {
        assertFalse(economicsService.isValidWithdrawal(402));
    }

    @Test
    @DisplayName("Withdraw 396 tokens (৳99) rejected (below ৳100 minimum)")
    void testWithdrawBelowMinimum() {
        assertFalse(economicsService.isValidWithdrawal(396));
    }
}
