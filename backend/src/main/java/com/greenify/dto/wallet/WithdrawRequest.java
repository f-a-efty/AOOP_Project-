package com.greenify.dto.wallet;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class WithdrawRequest {
    @NotNull(message = "Tokens amount is required")
    @Min(value = 400, message = "Minimum withdrawal is 400 tokens (৳100 BDT)")
    private Integer tokens;

    @NotBlank(message = "bKash account number is required")
    private String bkashNumber;
}
