package com.greenify.dto.auth;

import com.greenify.domain.enums.OtpPurpose;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class SendOtpRequest {
    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^(\\+8801[3-9]\\d{8}|01[3-9]\\d{8})$", message = "Invalid Bangladesh phone number format")
    private String phoneNumber;

    @NotNull(message = "OTP Purpose is required")
    private OtpPurpose purpose;
}
