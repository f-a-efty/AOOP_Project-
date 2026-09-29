package com.greenify.controller;

import com.greenify.entity.Collection;
import com.greenify.entity.PickupRequest;
import com.greenify.entity.SmartBooth;
import com.greenify.entity.Vehicle;
import com.greenify.repository.CollectionRepository;
import com.greenify.repository.PickupRequestRepository;
import com.greenify.repository.SmartBoothRepository;
import com.greenify.repository.VehicleRepository;
import com.greenify.security.UserPrincipal;
import com.greenify.service.PickupService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/company")
@PreAuthorize("hasAnyRole('COMPANY', 'ADMIN')")
@RequiredArgsConstructor
public class CompanyController {

    private final SmartBoothRepository boothRepository;
    private final PickupRequestRepository pickupRequestRepository;
    private final VehicleRepository vehicleRepository;
    private final CollectionRepository collectionRepository;
    private final PickupService pickupService;

    @GetMapping("/dashboard")
    public ResponseEntity<?> getCompanyDashboard(@AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = 1L; // Dynamic mapping for authenticated company
        List<SmartBooth> booths = boothRepository.findByCompanyCompanyId(companyId);
        long pickupRequiredCount = pickupRequestRepository.countPendingPickupsForCompany(companyId);
        BigDecimal totalCollectedKg = collectionRepository.getTotalCollectedKgByCompany(companyId);

        return ResponseEntity.ok(Map.of(
                "companyId", companyId,
                "assignedBoothsCount", booths.size(),
                "totalPlasticCollectedKg", totalCollectedKg,
                "pickupRequiredCount", pickupRequiredCount,
                "booths", booths
        ));
    }

    @GetMapping("/booths")
    public ResponseEntity<List<SmartBooth>> getAssignedBooths(@AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = 1L;
        return ResponseEntity.ok(boothRepository.findByCompanyCompanyId(companyId));
    }

    @GetMapping("/pickup-requests")
    public ResponseEntity<List<PickupRequest>> getPickupRequests(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) String status) {
        Long companyId = 1L;
        return ResponseEntity.ok(pickupService.getCompanyPickupRequests(companyId, status));
    }

    @PostMapping("/pickup-requests/{id}/accept")
    public ResponseEntity<PickupRequest> acceptPickup(@PathVariable Long id) {
        return ResponseEntity.ok(pickupService.acceptPickupRequest(id));
    }

    @PostMapping("/pickup-requests/{id}/assign-vehicle")
    public ResponseEntity<PickupRequest> assignVehicle(
            @PathVariable Long id,
            @RequestBody Map<String, Long> body) {
        Long vehicleId = body.get("vehicleId");
        return ResponseEntity.ok(pickupService.assignVehicleToPickup(id, vehicleId));
    }

    @PostMapping("/pickup-requests/{id}/complete")
    public ResponseEntity<Collection> completePickup(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {
        String plasticGrade = (body != null && body.containsKey("plasticGrade")) ? body.get("plasticGrade") : "PET 100% Sorted";
        return ResponseEntity.ok(pickupService.completePickup(id, plasticGrade));
    }

    @GetMapping("/vehicles")
    public ResponseEntity<List<Vehicle>> getVehicles(@AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = 1L;
        return ResponseEntity.ok(vehicleRepository.findByCompanyCompanyId(companyId));
    }

    @PostMapping("/vehicles")
    public ResponseEntity<Vehicle> createVehicle(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody Vehicle vehicle) {
        Long companyId = 1L;
        vehicle.setStatus("Available");
        return ResponseEntity.ok(vehicleRepository.save(vehicle));
    }

    @GetMapping("/collections")
    public ResponseEntity<List<Collection>> getCollections(@AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = 1L;
        return ResponseEntity.ok(collectionRepository.findByCompanyCompanyIdOrderByCollectedAtDesc(companyId));
    }
}
