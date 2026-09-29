package com.greenify.repository;

import com.greenify.entity.Vehicle;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    List<Vehicle> findByCompanyCompanyId(Long companyId);

    List<Vehicle> findByCompanyCompanyIdAndStatus(Long companyId, String status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT v FROM Vehicle v WHERE v.vehicleId = :vehicleId")
    Optional<Vehicle> findByIdWithLock(@Param("vehicleId") Long vehicleId);
}
