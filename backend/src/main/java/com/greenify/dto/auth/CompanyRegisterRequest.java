package com.greenify.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CompanyRegisterRequest {
    @NotBlank(message = "Company name is required")
    private String companyName;

    @NotBlank(message = "Registration number is required")
    private String registrationNumber;

    private String permitInfo;

    @NotBlank(message = "Official email is required")
    @Email(message = "Invalid email address format")
    private String contactEmail;

    @NotBlank(message = "Official phone number is required")
    private String contactPhone;

    private String contactPersonName;
    private String contactPersonPhone;
    private String contactPersonEmail;
    private String companyAddress;
    private String region;

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters long")
    @Pattern(regexp = ".*\\d.*", message = "Password must contain at least one number")
    private String password;

    @NotBlank(message = "Confirm password is required")
    private String confirmPassword;
}
