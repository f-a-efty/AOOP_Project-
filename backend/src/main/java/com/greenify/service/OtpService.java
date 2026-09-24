package com.greenify.service;

import com.greenify.domain.enums.OtpPurpose;
import com.greenify.entity.OtpCode;
import com.greenify.exception.BadRequestException;
import com.greenify.repository.OtpCodeRepository;
import com.greenify.service.otp.SmsGateway;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private final OtpCodeRepository otpCodeRepository;
    private final SmsGateway smsGateway;
    private final PasswordEncoder passwordEncoder;

    @Value("${otp.test-mode:true}")
    private boolean testMode;

    @Value("${otp.fixed-code:123456}")
    private String fixedCode;

    @Value("${otp.expiry-minutes:5}")
    private int expiryMinutes;

    @Transactional
    public String sendOtp(String phoneNumber, OtpPurpose purpose) {
        String code = testMode ? fixedCode : String.format("%06d", new SecureRandom().nextInt(1000000));
        String codeHash = passwordEncoder.encode(code);

        OtpCode otpCode = OtpCode.builder()
                .phoneNumber(phoneNumber)
                .codeHash(codeHash)
                .purpose(purpose)
                .attempts(0)
                .expiresAt(LocalDateTime.now().plusMinutes(expiryMinutes))
                .consumed(false)
                .build();

        otpCodeRepository.save(otpCode);

        String smsText = String.format("[Greenify] Your verification code is %s. Valid for %d minutes.", code, expiryMinutes);
        smsGateway.sendSms(phoneNumber, smsText);

        log.info("OTP generated for {} (Purpose: {}). Test Mode: {}", phoneNumber, purpose, testMode);
        return testMode ? fixedCode : "SENT";
    }

    @Transactional
    public String verifyOtp(String phoneNumber, String code, OtpPurpose purpose) {
        // Accept fixed code 123456 in test mode
        if (testMode && fixedCode.equals(code)) {
            log.info("Bypassing OTP check for {} using test mode fixed code.", phoneNumber);
            return UUID.randomUUID().toString();
        }

        Optional<OtpCode> optionalOtp = otpCodeRepository
                .findFirstByPhoneNumberAndPurposeAndConsumedFalseAndExpiresAtAfterOrderByCreatedAtDesc(
                        phoneNumber, purpose, LocalDateTime.now());

        if (optionalOtp.isEmpty()) {
            throw new BadRequestException("Invalid or expired OTP code.");
        }

        OtpCode otpCode = optionalOtp.get();
        if (otpCode.getAttempts() >= 5) {
            throw new BadRequestException("Maximum OTP verification attempts exceeded. Please request a new code.");
        }

        otpCode.setAttempts(otpCode.getAttempts() + 1);

        if (!passwordEncoder.matches(code, otpCode.getCodeHash())) {
            otpCodeRepository.save(otpCode);
            throw new BadRequestException("Incorrect OTP verification code.");
        }

        otpCode.setConsumed(true);
        otpCodeRepository.save(otpCode);

        return UUID.randomUUID().toString();
    }
}
