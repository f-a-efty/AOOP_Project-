package com.greenify.repository;

import com.greenify.entity.PickupRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PickupRequestRepository extends JpaRepository<PickupRequest, Long> {

    List<PickupRequest> findByCompanyCompanyIdOrderByPriorityDescCreatedAtAsc(Long companyId);

    List<PickupRequest> findByCompanyCompanyIdAndStatusOrderByPriorityDescCreatedAtAsc(Long companyId, String status);

    Optional<PickupRequest> findByBoothBoothIdAndStatusIn(Long boothId, List<String> statuses);

    @Query("SELECT COUNT(p) FROM PickupRequest p WHERE p.company.companyId = :companyId AND p.status IN ('Pending', 'Accepted')")
    long countPendingPickupsForCompany(@Param("companyId") Long companyId);
}
