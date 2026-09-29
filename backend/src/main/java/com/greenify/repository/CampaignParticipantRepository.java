package com.greenify.repository;

import com.greenify.entity.CampaignParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CampaignParticipantRepository extends JpaRepository<CampaignParticipant, Long> {

    boolean existsByCampaignCampaignIdAndUserUserId(Long campaignId, Long userId);

    Optional<CampaignParticipant> findByCampaignCampaignIdAndUserUserId(Long campaignId, Long userId);

    long countByCampaignCampaignId(Long campaignId);
}
