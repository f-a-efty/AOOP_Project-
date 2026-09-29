package com.greenify.repository;

import com.greenify.entity.WalletTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, Long> {

    List<WalletTransaction> findByUserUserIdOrderByTransactionTimestampDesc(Long userId);

    Optional<WalletTransaction> findByIdempotencyKey(String idempotencyKey);

    Optional<WalletTransaction> findByBkashTrxId(String bkashTrxId);

    List<WalletTransaction> findByStatus(String status);
}
