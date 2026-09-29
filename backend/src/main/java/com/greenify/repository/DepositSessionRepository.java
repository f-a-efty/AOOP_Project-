package com.greenify.repository;

import com.greenify.entity.DepositSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DepositSessionRepository extends JpaRepository<DepositSession, String> {
    Optional<DepositSession> findByQrTokenHash(String tokenHash);
}
