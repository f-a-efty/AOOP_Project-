package com.greenify.repository;

import com.greenify.entity.PlasticDeposit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface PlasticDepositRepository extends JpaRepository<PlasticDeposit, Long> {

    List<PlasticDeposit> findByUserUserIdOrderByDepositTimestampDesc(Long userId);

    @Query("SELECT COALESCE(SUM(p.plasticWeightKg), 0.000) FROM PlasticDeposit p WHERE p.user.userId = :userId")
    BigDecimal getTotalWeightKgByUserId(@Param("userId") Long userId);

    @Query("SELECT COALESCE(SUM(p.plasticWeightKg), 0.000) FROM PlasticDeposit p")
    BigDecimal getTotalPlatformWeightKg();
}
