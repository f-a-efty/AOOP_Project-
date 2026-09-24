package com.greenify.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "wallet_transactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WalletTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transaction_id")
    private Long transactionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "transaction_type", nullable = false, length = 30)
    private String transactionType;

    @Column(name = "tokens_delta", nullable = false)
    private Integer tokensDelta;

    @Column(name = "cash_delta", nullable = false, precision = 10, scale = 2)
    @Builder.Default
    private BigDecimal cashDelta = BigDecimal.ZERO;

    @Column(name = "balance_after_tokens", nullable = false)
    private Integer balanceAfterTokens;

    @Column(name = "bkash_trx_id", unique = true, length = 64)
    private String bkashTrxId;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "Completed";

    @Column(name = "idempotency_key", unique = true, length = 128)
    private String idempotencyKey;

    @CreationTimestamp
    @Column(name = "transaction_timestamp", updatable = false)
    private LocalDateTime transactionTimestamp;
}
