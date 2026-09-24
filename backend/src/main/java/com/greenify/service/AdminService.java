package com.greenify.service;

import com.greenify.domain.enums.CompanyStatus;
import com.greenify.domain.enums.UserStatus;
import com.greenify.entity.AuditLog;
import com.greenify.entity.RecyclingCompany;
import com.greenify.entity.SystemConfig;
import com.greenify.entity.User;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final RecyclingCompanyRepository companyRepository;
    private final SmartBoothRepository boothRepository;
    private final PlasticDepositRepository depositRepository;
    private final WalletTransactionRepository transactionRepository;
    private final SystemConfigRepository configRepository;
    private final AuditLogRepository auditLogRepository;

    public Map<String, Object> getDashboardMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("registeredUsers", userRepository.count());
        metrics.put("activeBooths", boothRepository.count());
        metrics.put("totalCompanies", companyRepository.count());
        metrics.put("totalPlasticKg", depositRepository.getTotalPlatformWeightKg());
        metrics.put("pendingCompanyApprovals", companyRepository.findByStatus(CompanyStatus.PENDING).size());
        return metrics;
    }

    @Transactional
    public RecyclingCompany approveCompany(Long companyId, String adminEmail) {
        RecyclingCompany company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company not found: " + companyId));

        company.setStatus(CompanyStatus.ACTIVE);
        companyRepository.save(company);

        logAudit(adminEmail, "APPROVE_COMPANY", "Approved company registration for " + company.getCompanyName(), "Companies");
        return company;
    }

    @Transactional
    public RecyclingCompany rejectCompany(Long companyId, String adminEmail) {
        RecyclingCompany company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company not found: " + companyId));

        company.setStatus(CompanyStatus.REJECTED);
        companyRepository.save(company);

        logAudit(adminEmail, "REJECT_COMPANY", "Rejected company registration for " + company.getCompanyName(), "Companies");
        return company;
    }

    @Transactional
    public User toggleUserStatus(Long userId, String adminEmail) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        UserStatus newStatus = (user.getStatus() == UserStatus.ACTIVE) ? UserStatus.SUSPENDED : UserStatus.ACTIVE;
        user.setStatus(newStatus);
        userRepository.save(user);

        logAudit(adminEmail, "TOGGLE_USER_STATUS", "Changed user status for ID " + userId + " to " + newStatus, "Users");
        return user;
    }

    @Transactional
    public void updateEconomicsConfig(String key, String value, String adminEmail) {
        SystemConfig config = configRepository.findById(key)
                .orElseGet(() -> SystemConfig.builder().configKey(key).description("Admin configured").build());

        String oldValue = config.getConfigValue();
        config.setConfigValue(value);
        configRepository.save(config);

        logAudit(adminEmail, "UPDATE_ECONOMICS_RULE", "Updated economics rule '" + key + "' from '" + oldValue + "' to '" + value + "'", "Finance");
    }

    public List<AuditLog> getAuditLogs() {
        return auditLogRepository.findAllByOrderByCreatedAtDesc();
    }

    private void logAudit(String adminEmail, String action, String detail, String module) {
        AuditLog logItem = AuditLog.builder()
                .adminEmail(adminEmail != null ? adminEmail : "admin@greenify.bd")
                .action(action)
                .detail(detail)
                .module(module)
                .build();
        auditLogRepository.save(logItem);
    }
}
