package com.greenify.service.payout;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PayoutResult {
    private boolean success;
    private String transactionId;
    private String errorMessage;
}
