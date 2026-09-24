package com.greenify.repository;

import com.greenify.domain.enums.CompanyStatus;
import com.greenify.entity.RecyclingCompany;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RecyclingCompanyRepository extends JpaRepository<RecyclingCompany, Long> {

    Optional<RecyclingCompany> findByContactEmail(String email);

    Optional<RecyclingCompany> findByRegistrationNumber(String regNum);

    boolean existsByContactEmail(String email);

    boolean existsByRegistrationNumber(String regNum);

    List<RecyclingCompany> findByStatus(CompanyStatus status);
}
