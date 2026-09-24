package com.greenify.controller;

import com.greenify.domain.enums.CompanyStatus;
import com.greenify.entity.AuditLog;
import com.greenify.entity.RecyclingCompany;
import com.greenify.entity.User;
import com.greenify.repository.RecyclingCompanyRepository;
import com.greenify.repository.UserRepository;
import com.greenify.security.UserPrincipal;
import com.greenify.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final UserRepository userRepository;
    private final RecyclingCompanyRepository companyRepository;

    @GetMapping("/dashboard/metrics")
    public ResponseEntity<Map<String, Object>> getMetrics() {
        return ResponseEntity.ok(adminService.getDashboardMetrics());
    }

    @GetMapping("/users")
    public ResponseEntity<List<User>> getAllUsers() {
        return ResponseEntity.ok(userRepository.findAll());
    }

    @PostMapping("/users/{userId}/toggle-status")
    public ResponseEntity<User> toggleUserStatus(
            @PathVariable Long userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        String email = principal != null ? principal.getUsername() : "admin@greenify.bd";
        return ResponseEntity.ok(adminService.toggleUserStatus(userId, email));
    }

    @GetMapping("/companies/pending")
    public ResponseEntity<List<RecyclingCompany>> getPendingCompanies() {
        return ResponseEntity.ok(companyRepository.findByStatus(CompanyStatus.PENDING));
    }

    @PostMapping("/companies/{companyId}/approve")
    public ResponseEntity<RecyclingCompany> approveCompany(
            @PathVariable Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        String email = principal != null ? principal.getUsername() : "admin@greenify.bd";
        return ResponseEntity.ok(adminService.approveCompany(companyId, email));
    }

    @PostMapping("/companies/{companyId}/reject")
    public ResponseEntity<RecyclingCompany> rejectCompany(
            @PathVariable Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        String email = principal != null ? principal.getUsername() : "admin@greenify.bd";
        return ResponseEntity.ok(adminService.rejectCompany(companyId, email));
    }

    @PostMapping("/config/economics")
    public ResponseEntity<?> updateEconomicsConfig(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        String key = body.get("key");
        String value = body.get("value");
        String email = principal != null ? principal.getUsername() : "admin@greenify.bd";
        adminService.updateEconomicsConfig(key, value, email);
        return ResponseEntity.ok(Map.of("success", true, "message", "Economics rule updated successfully."));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLog>> getAuditLogs() {
        return ResponseEntity.ok(adminService.getAuditLogs());
    }
}
