package com.greenify.repository;

import com.greenify.entity.SmartBooth;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SmartBoothRepository extends JpaRepository<SmartBooth, Long> {

    Optional<SmartBooth> findByBoothCode(String boothCode);

    List<SmartBooth> findByCompanyCompanyId(Long companyId);

    List<SmartBooth> findByBoothStatus(String status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT b FROM SmartBooth b WHERE b.boothId = :boothId")
    Optional<SmartBooth> findByIdWithLock(@Param("boothId") Long boothId);
}
