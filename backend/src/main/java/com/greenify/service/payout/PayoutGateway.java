package com.greenify.service.payout;

import java.math.BigDecimal;

public interface PayoutGateway {
    PayoutResult sendPayout(String bkashNumber, BigDecimal amountTaka, String reference);
}
