package com.greenify.repository;

import com.greenify.entity.Collection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface CollectionRepository extends JpaRepository<Collection, Long> {

    List<Collection> findByCompanyCompanyIdOrderByCollectedAtDesc(Long companyId);

    @Query("SELECT COALESCE(SUM(c.netWeightKg), 0.000) FROM Collection c WHERE c.company.companyId = :companyId")
    BigDecimal getTotalCollectedKgByCompany(@Param("companyId") Long companyId);

    @Query("SELECT COALESCE(SUM(c.netWeightKg), 0.000) FROM Collection c")
    BigDecimal getTotalPlatformCollectedKg();
}
