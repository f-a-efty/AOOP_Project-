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

    Optional<RecyclingCompany> findByContactPhone(String phone);

    Optional<RecyclingCompany> findByRegistrationNumber(String regNum);

    boolean existsByContactEmail(String email);

    boolean existsByContactPhone(String phone);

    boolean existsByRegistrationNumber(String regNum);

    List<RecyclingCompany> findByStatus(CompanyStatus status);
}
