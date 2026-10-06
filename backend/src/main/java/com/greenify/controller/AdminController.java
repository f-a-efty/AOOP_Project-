package com.greenify.controller;

import com.greenify.domain.enums.CompanyStatus;
import com.greenify.entity.AuditLog;
import com.greenify.entity.RecyclingCompany;
import com.greenify.entity.User;
import com.greenify.repository.RecyclingCompanyRepository;
import com.greenify.repository.UserRepository;
import com.greenify.security.UserPrincipal;
import com.greenify.service.AdminService;
import com.greenify.service.GeminiService;
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

    private final GeminiService geminiService;

    @GetMapping("/ai/environmental-prediction")
    public ResponseEntity<Map<String, Object>> getEnvironmentalPrediction(
            @RequestParam(required = false) String query) {
        return ResponseEntity.ok(geminiService.getEnvironmentalPrediction(query));
    }

    @PostMapping("/ai/environmental-prediction/generate")
    public ResponseEntity<Map<String, Object>> generateEnvironmentalPrediction(
            @RequestBody(required = false) Map<String, String> body) {
        String query = body != null ? body.get("query") : null;
        return ResponseEntity.ok(geminiService.getEnvironmentalPrediction(query));
    }

    @GetMapping("/ai/gemini-config")
    public ResponseEntity<Map<String, Object>> getGeminiConfig() {
        return ResponseEntity.ok(geminiService.getGeminiConfig());
    }

    @PostMapping("/ai/gemini-config")
    public ResponseEntity<?> saveGeminiConfig(@RequestBody Map<String, String> body) {
        String apiKey = body.get("apiKey");
        geminiService.saveGeminiApiKey(apiKey);
        return ResponseEntity.ok(Map.of("success", true, "message", "Gemini API key saved successfully."));
    }

    private final com.greenify.repository.CampaignRepository campaignRepository;
    private final com.greenify.repository.CouponRepository couponRepository;
    private final com.greenify.repository.PlasticDepositRepository depositRepository;
    private final com.greenify.repository.SmartBoothRepository boothRepository;

    @GetMapping("/companies/active")
    public ResponseEntity<List<RecyclingCompany>> getActiveCompanies() {
        return ResponseEntity.ok(companyRepository.findByStatus(CompanyStatus.ACTIVE));
    }

    @GetMapping("/dashboard/activity")
    public ResponseEntity<?> getActivity(@RequestParam(defaultValue = "15") int limit) {
        var deposits = depositRepository.findAll().stream()
                .sorted((a, b) -> b.getDepositTimestamp().compareTo(a.getDepositTimestamp()))
                .limit(limit)
                .map(d -> Map.of(
                        "activityType", "deposit",
                        "title", "Plastic deposited",
                        "description", d.getUser().getFullName() + " deposited " + d.getPlasticWeightKg() + " kg (" + d.getTokensEarned() + " tokens)",
                        "createdAt", d.getDepositTimestamp().toString()
                ))
                .toList();
        return ResponseEntity.ok(deposits);
    }

    @GetMapping("/reports/analytics")
    public ResponseEntity<Map<String, Object>> getAnalytics(@RequestParam(defaultValue = "30") int days) {
        double totalKg = depositRepository.findAll().stream()
                .mapToDouble(d -> d.getPlasticWeightKg().doubleValue()).sum();
        long totalTokens = depositRepository.findAll().stream()
                .mapToLong(com.greenify.entity.PlasticDeposit::getTokensEarned).sum();
        long activeBooths = boothRepository.count();

        return ResponseEntity.ok(Map.of(
                "totalPlasticKg", totalKg,
                "totalTokensIssued", totalTokens,
                "activeBoothsCount", activeBooths,
                "co2PreventedKg", totalKg * 1.5,
                "diversionRatePct", 92.4,
                "timeWindowDays", days
        ));
    }

    @GetMapping("/campaigns")
    public ResponseEntity<?> getCampaigns() {
        return ResponseEntity.ok(campaignRepository.findAll());
    }

    @PostMapping("/campaigns")
    public ResponseEntity<?> createCampaign(@RequestBody com.greenify.entity.Campaign campaign) {
        campaign.setStatus("Active");
        return ResponseEntity.ok(campaignRepository.save(campaign));
    }

    @DeleteMapping("/campaigns/{id}")
    public ResponseEntity<?> deleteCampaign(@PathVariable Long id) {
        campaignRepository.deleteById(id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/coupons")
    public ResponseEntity<?> getCoupons() {
        return ResponseEntity.ok(couponRepository.findAll());
    }

    @PostMapping("/coupons")
    public ResponseEntity<?> createCoupon(@RequestBody com.greenify.entity.Coupon coupon) {
        return ResponseEntity.ok(couponRepository.save(coupon));
    }

    @DeleteMapping("/coupons/{id}")
    public ResponseEntity<?> deleteCoupon(@PathVariable Long id) {
        couponRepository.deleteById(id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/loyalty-levels")
    public ResponseEntity<?> getLoyaltyLevels() {
        return ResponseEntity.ok(List.of(
                Map.of("level", "Eco Novice", "minKg", 0, "maxKg", 10, "perks", "Standard 100 tokens/kg", "badge", "Bronze Leaf"),
                Map.of("level", "Eco Buddy", "minKg", 10, "maxKg", 50, "perks", "+5% bonus tokens, monthly raffle ticket", "badge", "Silver Sprout"),
                Map.of("level", "Eco Champion", "minKg", 50, "maxKg", 200, "perks", "+10% bonus tokens, priority cashout", "badge", "Gold Tree"),
                Map.of("level", "Planet Savior", "minKg", 200, "maxKg", 10000, "perks", "+15% bonus tokens, VIP certificate", "badge", "Diamond Globe")
        ));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLog>> getAuditLogs() {
        return ResponseEntity.ok(adminService.getAuditLogs());
    }
}
