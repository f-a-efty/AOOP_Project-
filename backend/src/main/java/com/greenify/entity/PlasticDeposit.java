package com.greenify.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "plastic_deposits")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PlasticDeposit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "deposit_id")
    private Long depositId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booth_id", nullable = false)
    private SmartBooth booth;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false, unique = true)
    private DepositSession session;

    @Column(name = "plastic_weight_kg", nullable = false, precision = 8, scale = 3)
    private BigDecimal plasticWeightKg;

    @Column(name = "plastic_type", length = 50)
    @Builder.Default
    private String plasticType = "PET/Mix";

    @Column(name = "tokens_earned", nullable = false)
    private Integer tokensEarned;

    @Column(name = "rate_snapshot", nullable = false)
    @Builder.Default
    private Integer rateSnapshot = 100;

    @CreationTimestamp
    @Column(name = "deposit_timestamp", updatable = false)
    private LocalDateTime depositTimestamp;
}
