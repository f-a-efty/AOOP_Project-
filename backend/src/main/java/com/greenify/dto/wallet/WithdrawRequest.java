package com.greenify.dto.wallet;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class WithdrawRequest {
    @NotNull(message = "Tokens amount is required")
    @Min(value = 100, message = "Minimum withdrawal is 100 tokens (৳25 BDT)")
    private Integer tokens;

    @NotBlank(message = "bKash account number is required")
    private String bkashNumber;
}
