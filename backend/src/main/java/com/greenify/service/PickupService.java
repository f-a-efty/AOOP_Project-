package com.greenify.service;

import com.greenify.entity.*;
import com.greenify.exception.BadRequestException;
import com.greenify.exception.ResourceNotFoundException;
import com.greenify.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PickupService {

    private final PickupRequestRepository pickupRequestRepository;
    private final VehicleRepository vehicleRepository;
    private final SmartBoothRepository boothRepository;
    private final CollectionRepository collectionRepository;

    public List<PickupRequest> getCompanyPickupRequests(Long companyId, String status) {
        if (status != null && !status.isBlank()) {
            return pickupRequestRepository.findByCompanyCompanyIdAndStatusOrderByPriorityDescCreatedAtAsc(companyId, status);
        }
        return pickupRequestRepository.findByCompanyCompanyIdOrderByPriorityDescCreatedAtAsc(companyId);
    }

    @Transactional
    public PickupRequest acceptPickupRequest(Long requestId) {
        PickupRequest request = pickupRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Pickup request not found: " + requestId));

        if (!"Pending".equalsIgnoreCase(request.getStatus())) {
            throw new BadRequestException("Only Pending pickup requests can be accepted.");
        }

        request.setStatus("Accepted");
        request.setAcceptedAt(LocalDateTime.now());
        return pickupRequestRepository.save(request);
    }

    @Transactional
    public PickupRequest assignVehicleToPickup(Long requestId, Long vehicleId) {
        PickupRequest request = pickupRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Pickup request not found: " + requestId));

        // Row lock vehicle for single-assignment enforcement
        Vehicle vehicle = vehicleRepository.findByIdWithLock(vehicleId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found: " + vehicleId));

        if (!"Available".equalsIgnoreCase(vehicle.getStatus())) {
            throw new BadRequestException("Vehicle " + vehicle.getVehicleNumber() + " is currently unavailable (Status: " + vehicle.getStatus() + ").");
        }

        vehicle.setStatus("Assigned");
        vehicleRepository.save(vehicle);

        request.setVehicle(vehicle);
        request.setStatus("Vehicle Assigned");
        return pickupRequestRepository.save(request);
    }

    @Transactional
    public PickupRequest startPickup(Long requestId) {
        PickupRequest request = pickupRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Pickup request not found: " + requestId));

        if (request.getVehicle() != null) {
            request.getVehicle().setStatus("On Pickup");
            vehicleRepository.save(request.getVehicle());
        }

        request.setStatus("On Pickup");
        return pickupRequestRepository.save(request);
    }

    @Transactional
    public Collection completePickup(Long requestId, String plasticGrade) {
        PickupRequest request = pickupRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Pickup request not found: " + requestId));

        SmartBooth booth = boothRepository.findByIdWithLock(request.getBooth().getBoothId())
                .orElseThrow(() -> new ResourceNotFoundException("Booth not found: " + request.getBooth().getBoothId()));

        BigDecimal netCollectedKg = booth.getCurrentWeightKg();

        // 1. Reset booth capacity
        booth.setCurrentWeightKg(BigDecimal.ZERO);
        booth.setBoothStatus("Empty");
        booth.setLastPickupDate(LocalDateTime.now());
        boothRepository.save(booth);

        // 2. Free assigned vehicle
        Vehicle vehicle = request.getVehicle();
        if (vehicle != null) {
            vehicle.setStatus("Available");
            vehicleRepository.save(vehicle);
        }

        // 3. Mark request completed
        request.setStatus("Completed");
        request.setCompletedAt(LocalDateTime.now());
        pickupRequestRepository.save(request);

        // 4. Log collection record
        Collection collection = Collection.builder()
                .pickupRequest(request)
                .booth(booth)
                .company(request.getCompany())
                .netWeightKg(netCollectedKg)
                .plasticGrade(plasticGrade != null ? plasticGrade : "PET 100% Sorted")
                .build();

        collection = collectionRepository.save(collection);

        log.info("Pickup request {} completed for Booth {}. Collected {} kg.",
                request.getRequestCode(), booth.getBoothCode(), netCollectedKg);

        return collection;
    }
}
