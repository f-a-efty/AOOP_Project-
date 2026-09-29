package com.greenify.repository;

import com.greenify.entity.UserCouponRedemption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserCouponRedemptionRepository extends JpaRepository<UserCouponRedemption, Long> {
    List<UserCouponRedemption> findByUserUserIdOrderByRedeemedAtDesc(Long userId);
}
