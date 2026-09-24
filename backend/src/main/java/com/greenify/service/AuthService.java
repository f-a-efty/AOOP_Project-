package com.greenify.service;

import com.greenify.domain.enums.CompanyStatus;
import com.greenify.domain.enums.OtpPurpose;
import com.greenify.domain.enums.Role;
import com.greenify.domain.enums.UserStatus;
import com.greenify.dto.auth.*;
import com.greenify.entity.RecyclingCompany;
import com.greenify.entity.RefreshToken;
import com.greenify.entity.User;
import com.greenify.exception.BadRequestException;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.exception.UnauthorizedException;
import com.greenify.repository.RecyclingCompanyRepository;
import com.greenify.repository.RefreshTokenRepository;
import com.greenify.repository.UserRepository;
import com.greenify.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RecyclingCompanyRepository companyRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final OtpService otpService;
    private final JwtTokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public AuthResponse registerUser(UserRegisterRequest request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Password and confirm password do not match.");
        }

        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new BadRequestException("Phone number is already registered.");
        }

        otpService.verifyOtp(request.getPhoneNumber(), request.getOtpCode(), OtpPurpose.REGISTER);

        User user = User.builder()
                .fullName(request.getFullName())
                .phoneNumber(request.getPhoneNumber())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .totalTokens(0)
                .loyaltyLevel("Eco Buddy")
                .role(Role.USER)
                .status(UserStatus.ACTIVE)
                .build();

        user = userRepository.save(user);

        String accessToken = tokenProvider.generateAccessToken(user.getUserId(), user.getPhoneNumber(), user.getRole().name());
        String refreshToken = createRefreshToken(user);

        return AuthResponse.builder()
                .success(true)
                .message("User account registered successfully.")
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .fullName(user.getFullName())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole().name())
                .build();
    }

    @Transactional
    public AuthResponse registerCompany(CompanyRegisterRequest request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Password and confirm password do not match.");
        }

        if (companyRepository.existsByContactEmail(request.getContactEmail())) {
            throw new BadRequestException("Company email is already registered.");
        }

        if (companyRepository.existsByRegistrationNumber(request.getRegistrationNumber())) {
            throw new BadRequestException("Registration number is already in use.");
        }

        RecyclingCompany company = RecyclingCompany.builder()
                .companyName(request.getCompanyName())
                .registrationNumber(request.getRegistrationNumber())
                .permitInfo(request.getPermitInfo())
                .contactEmail(request.getContactEmail())
                .contactPhone(request.getContactPhone())
                .contactPersonName(request.getContactPersonName())
                .contactPersonPhone(request.getContactPersonPhone())
                .contactPersonEmail(request.getContactPersonEmail())
                .companyAddress(request.getCompanyAddress())
                .region(request.getRegion())
                .status(CompanyStatus.PENDING)
                .build();

        companyRepository.save(company);

        User companyUser = User.builder()
                .fullName(request.getCompanyName() + " Manager")
                .phoneNumber(request.getContactPhone())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .totalTokens(0)
                .role(Role.COMPANY)
                .status(UserStatus.ACTIVE)
                .build();

        userRepository.save(companyUser);

        return AuthResponse.builder()
                .success(true)
                .message("Company registration submitted successfully. Pending administrator approval.")
                .role(Role.COMPANY.name())
                .companyStatus(CompanyStatus.PENDING.name())
                .build();
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByPhoneNumber(request.getUsername())
                .orElseGet(() -> userRepository.findAll().stream()
                        .filter(u -> u.getRole() == Role.COMPANY || u.getRole() == Role.ADMIN)
                        .filter(u -> request.getUsername().equalsIgnoreCase(u.getPhoneNumber()))
                        .findFirst()
                        .orElseThrow(() -> new UnauthorizedException("Invalid phone number/email or password.")));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new UnauthorizedException("Invalid phone number/email or password.");
        }

        if (user.getStatus() == UserStatus.SUSPENDED) {
            throw new UnauthorizedException("Your account has been suspended. Please contact support.");
        }

        String accessToken = tokenProvider.generateAccessToken(user.getUserId(), user.getPhoneNumber(), user.getRole().name());
        String refreshToken = createRefreshToken(user);

        return AuthResponse.builder()
                .success(true)
                .message("Login successful.")
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .fullName(user.getFullName())
                .phoneNumber(user.getPhoneNumber())
                .role(user.getRole().name())
                .build();
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken token = refreshTokenRepository.findByTokenHash(request.getRefreshToken())
                .orElseThrow(() -> new UnauthorizedException("Invalid refresh token."));

        if (token.getRevoked() || token.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new UnauthorizedException("Expired or revoked refresh token.");
        }

        User user = token.getUser();
        token.setRevoked(true);
        refreshTokenRepository.save(token);

        String newAccessToken = tokenProvider.generateAccessToken(user.getUserId(), user.getPhoneNumber(), user.getRole().name());
        String newRefreshToken = createRefreshToken(user);

        return AuthResponse.builder()
                .success(true)
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .userId(user.getUserId())
                .role(user.getRole().name())
                .build();
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("New password and confirm password do not match.");
        }

        // For reset Token, update matching user password and revoke all existing refresh tokens
        User user = userRepository.findAll().stream().findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("User not found."));

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        refreshTokenRepository.revokeAllUserTokens(user.getUserId());
        log.info("Password reset successfully for user ID {}. Revoked active refresh tokens.", user.getUserId());
    }

    private String createRefreshToken(User user) {
        String tokenStr = tokenProvider.generateRefreshToken(user.getUserId());
        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenStr)
                .expiresAt(LocalDateTime.now().plusNanos(tokenProvider.getRefreshTokenExpirationMs() * 1_000_000))
                .revoked(false)
                .build();
        refreshTokenRepository.save(refreshToken);
        return tokenStr;
    }
}
