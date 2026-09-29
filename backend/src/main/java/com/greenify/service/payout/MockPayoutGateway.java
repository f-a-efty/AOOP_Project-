package com.greenify.service.payout;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Service
@ConditionalOnProperty(name = "payout.provider", havingValue = "mock", matchIfMissing = true)
public class MockPayoutGateway implements PayoutGateway {

    @Override
    public PayoutResult sendPayout(String bkashNumber, BigDecimal amountTaka, String reference) {
        log.info("[MOCK PAYOUT GATEWAY] Processing payout of ৳{} BDT to bKash number {} (Ref: {})",
                amountTaka, bkashNumber, reference);

        // Magic failure trigger for testing failure rollback
        if (bkashNumber != null && bkashNumber.endsWith("999")) {
            log.warn("[MOCK PAYOUT GATEWAY] Simulated failure triggered for number: {}", bkashNumber);
            return PayoutResult.builder()
                    .success(false)
                    .errorMessage("Simulated bKash account validation failure for test number.")
                    .build();
        }

        String mockTrxId = "BKASH_MOCK_TX_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        log.info("[MOCK PAYOUT GATEWAY] Payout successful. Transaction ID: {}", mockTrxId);

        return PayoutResult.builder()
                .success(true)
                .transactionId(mockTrxId)
                .build();
    }
}
