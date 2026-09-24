package com.greenify.controller;

import com.greenify.entity.PlasticDeposit;
import com.greenify.service.DepositService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/booths")
@RequiredArgsConstructor
public class BoothController {

    private final DepositService depositService;

    @PostMapping("/{boothId}/qr")
    public ResponseEntity<?> generateQrToken(@PathVariable Long boothId) {
        String qrToken = depositService.generateBoothQrToken(boothId);
        return ResponseEntity.ok(Map.of(
                "success", true,
                "boothId", boothId,
                "qrToken", qrToken,
                "ttlSeconds", 60
        ));
    }

    @PostMapping("/{boothId}/deposit-sessions/{sessionId}/weight")
    public ResponseEntity<PlasticDeposit> submitWeight(
            @PathVariable Long boothId,
            @PathVariable String sessionId,
            @RequestBody Map<String, Object> body) {
        BigDecimal weightKg = new BigDecimal(body.get("weightKg").toString());
        String plasticType = body.containsKey("plasticType") ? body.get("plasticType").toString() : "PET/Mix";

        PlasticDeposit deposit = depositService.submitPlasticWeight(boothId, sessionId, weightKg, plasticType);
        return ResponseEntity.ok(deposit);
    }

    @PostMapping("/{boothId}/heartbeat")
    public ResponseEntity<?> heartbeat(@PathVariable Long boothId) {
        return ResponseEntity.ok(Map.of("status", "ONLINE", "boothId", boothId));
    }
}
