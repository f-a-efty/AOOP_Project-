package com.greenify.dto.auth;

import com.greenify.domain.enums.OtpPurpose;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class VerifyOtpRequest {
    @NotBlank(message = "Phone number is required")
    private String phoneNumber;

    @NotBlank(message = "OTP code is required")
    private String code;

    @NotNull(message = "OTP Purpose is required")
    private OtpPurpose purpose;
}
