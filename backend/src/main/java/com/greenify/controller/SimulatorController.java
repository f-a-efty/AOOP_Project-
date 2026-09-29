package com.greenify.controller;

import com.greenify.entity.SmartBooth;
import com.greenify.repository.SmartBoothRepository;
import com.greenify.service.DepositService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/sim")
@RequiredArgsConstructor
public class SimulatorController {

    private final SmartBoothRepository boothRepository;
    private final DepositService depositService;

    @GetMapping(produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getSimulatorPage() {
        List<SmartBooth> booths = boothRepository.findAll();
        StringBuilder options = new StringBuilder();
        for (SmartBooth b : booths) {
            options.append(String.format("<option value='%d'>%s - %s (Current: %s kg)</option>",
                    b.getBoothId(), b.getBoothCode(), b.getLocationAddress(), b.getCurrentWeightKg()));
        }

        String html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Greenify Smart Booth Hardware Simulator</title>
                    <style>
                        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #F2F5F1; margin: 40px; color: #192718; }
                        .card { background: white; border-radius: 12px; padding: 24px; max-width: 600px; margin: auto; box-shadow: 0 4px 12px rgba(0,0,0,0.08); border: 1px solid #D9E4D6; }
                        h1 { color: #2E6027; margin-top: 0; }
                        button { background: #2E6027; color: white; border: none; padding: 12px 20px; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 16px; margin-top: 10px; }
                        button:hover { background: #3D7A35; }
                        select, input { width: 100%%; padding: 10px; margin: 8px 0 16px; border: 1px solid #D9E4D6; border-radius: 6px; box-sizing: border-box; }
                        .qr-box { background: #ECF2EA; border: 2px dashed #6BBF3A; padding: 20px; text-align: center; border-radius: 8px; margin: 16px 0; font-family: monospace; font-size: 18px; color: #2E6027; word-break: break-all; }
                    </style>
                </head>
                <body>
                    <div class="card">
                        <h1>♻️ Greenify Smart Booth Simulator</h1>
                        <p>Simulate plastic deposit hardware scale & dynamic QR code generation.</p>
                        
                        <label><b>Select Booth:</b></label>
                        <select id="boothSelect">
                            %s
                        </select>
                        
                        <button onclick="generateQr()">1. Generate Dynamic QR Code</button>
                        
                        <div id="qrArea" style="display:none;">
                            <p><b>Active Dynamic QR Token (TTL: 60s):</b></p>
                            <div class="qr-box" id="qrTokenDisplay"></div>
                        </div>

                        <hr style="margin: 24px 0; border: none; border-top: 1px solid #D9E4D6;">
                        
                        <label><b>2. Enter Measured Plastic Weight (kg):</b></label>
                        <input type="number" id="weightInput" step="0.001" placeholder="e.g. 1.500" value="1.000">
                        
                        <label><b>Session ID (Created from User App Scan):</b></label>
                        <input type="text" id="sessionIdInput" placeholder="Paste session_id from app scan API">
                        
                        <button onclick="submitWeight()">3. Submit Deposit Scale Telemetry</button>
                        
                        <div id="resultArea" style="margin-top: 16px;"></div>
                    </div>

                    <script>
                        async function generateQr() {
                            const boothId = document.getElementById('boothSelect').value;
                            const res = await fetch('/api/v1/booths/' + boothId + '/qr', { method: 'POST' });
                            const data = await res.json();
                            if (data.qrToken) {
                                document.getElementById('qrTokenDisplay').innerText = data.qrToken;
                                document.getElementById('qrArea').style.display = 'block';
                            } else {
                                alert(data.message || 'Failed to generate QR');
                            }
                        }

                        async function submitWeight() {
                            const boothId = document.getElementById('boothSelect').value;
                            const sessionId = document.getElementById('sessionIdInput').value;
                            const weightKg = document.getElementById('weightInput').value;
                            
                            if (!sessionId) {
                                alert('Please provide a valid session ID!');
                                return;
                            }

                            const res = await fetch('/api/v1/booths/' + boothId + '/deposit-sessions/' + sessionId + '/weight', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ weightKg: parseFloat(weightKg), plasticType: 'PET/Mix' })
                            });
                            const data = await res.json();
                            document.getElementById('resultArea').innerHTML = '<pre style="background:#ECF2EA; padding:12px; border-radius:6px;">' + JSON.stringify(data, null, 2) + '</pre>';
                        }
                    </script>
                </body>
                </html>
                """.formatted(options.toString());

        return ResponseEntity.ok(html);
    }
}
