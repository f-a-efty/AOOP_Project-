package com.greenify.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "smart_booths")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SmartBooth {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "booth_id")
    private Long boothId;

    @Column(name = "booth_code", nullable = false, unique = true, length = 50)
    private String boothCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id")
    private RecyclingCompany company;

    @Column(name = "location_address", nullable = false, length = 255)
    private String locationAddress;

    @Column(name = "latitude", precision = 10, scale = 8)
    private BigDecimal latitude;

    @Column(name = "longitude", precision = 11, scale = 8)
    private BigDecimal longitude;

    @Column(name = "capacity_kg", nullable = false, precision = 8, scale = 3)
    @Builder.Default
    private BigDecimal capacityKg = new BigDecimal("100.000");

    @Column(name = "current_weight_kg", nullable = false, precision = 8, scale = 3)
    @Builder.Default
    private BigDecimal currentWeightKg = BigDecimal.ZERO;

    @Column(name = "booth_status", nullable = false, length = 30)
    @Builder.Default
    private String boothStatus = "Empty";

    @Column(name = "sensor_status", length = 50)
    @Builder.Default
    private String sensorStatus = "Online";

    @Column(name = "last_pickup_date")
    private LocalDateTime lastPickupDate;
}
