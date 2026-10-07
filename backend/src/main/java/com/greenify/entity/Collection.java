package com.greenify.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "collections")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Collection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "collection_id")
    private Long collectionId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pickup_request_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "booth", "company", "vehicle"})
    private PickupRequest pickupRequest;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booth_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "company"})
    private SmartBooth booth;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private RecyclingCompany company;

    @Column(name = "net_weight_kg", nullable = false, precision = 8, scale = 3)
    private BigDecimal netWeightKg;

    @Column(name = "plastic_grade", length = 50)
    @Builder.Default
    private String plasticGrade = "PET 100% Sorted";

    @CreationTimestamp
    @Column(name = "collected_at", updatable = false)
    private LocalDateTime collectedAt;
}
