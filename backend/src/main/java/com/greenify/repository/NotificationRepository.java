package com.greenify.repository;

import com.greenify.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByRecipientRoleOrderByCreatedAtDesc(String recipientRole);

    List<Notification> findByRecipientRoleAndRecipientIdOrderByCreatedAtDesc(String recipientRole, Long recipientId);

    long countByRecipientRoleAndIsReadFalse(String recipientRole);

    long countByRecipientRoleAndRecipientIdAndIsReadFalse(String recipientRole, Long recipientId);
}
