package com.greenify.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "Phone number or email is required")
    private String username;

    @NotBlank(message = "Password is required")
    private String password;
}
