package com.greenify.repository;

import com.greenify.domain.enums.OtpPurpose;
import com.greenify.entity.OtpCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface OtpCodeRepository extends JpaRepository<OtpCode, Long> {

    Optional<OtpCode> findFirstByPhoneNumberAndPurposeAndConsumedFalseAndExpiresAtAfterOrderByCreatedAtDesc(
            String phoneNumber, OtpPurpose purpose, LocalDateTime now);
}
