package com.greenify.controller;

import com.greenify.domain.enums.Role;
import com.greenify.entity.PlasticDeposit;
import com.greenify.entity.SmartBooth;
import com.greenify.entity.User;
import com.greenify.repository.SmartBoothRepository;
import com.greenify.repository.UserRepository;
import com.greenify.service.DepositService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/sim")
@RequiredArgsConstructor
public class SimulatorController {

    private final SmartBoothRepository boothRepository;
    private final UserRepository userRepository;
    private final DepositService depositService;

    @GetMapping(value = {"", "/"}, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getSimulatorPage() {
        String html = """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Greenify Smart Booth Hardware & IoT Simulator</title>
                    <link rel="preconnect" href="https://fonts.googleapis.com">
                    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
                    <style>
                        :root {
                            --primary: #15803D;
                            --primary-light: #22C55E;
                            --primary-dark: #166534;
                            --bg: #F8FAFC;
                            --card-bg: #FFFFFF;
                            --text: #0F172A;
                            --text-muted: #64748B;
                            --border: #E2E8F0;
                            --danger: #DC2626;
                            --warning: #D97706;
                            --info: #0284C7;
                        }
                        * { box-sizing: border-box; margin: 0; padding: 0; }
                        body {
                            font-family: 'Plus Jakarta Sans', sans-serif;
                            background-color: var(--bg);
                            color: var(--text);
                            padding: 24px 16px;
                            min-height: 100vh;
                        }
                        .container {
                            max-width: 1080px;
                            margin: 0 auto;
                        }
                        header {
                            display: flex;
                            align-items: center;
                            justify-content: space-between;
                            background: white;
                            padding: 20px 28px;
                            border-radius: 16px;
                            box-shadow: 0 4px 20px -2px rgba(0,0,0,0.05);
                            border: 1px solid var(--border);
                            margin-bottom: 24px;
                        }
                        .header-title {
                            display: flex;
                            align-items: center;
                            gap: 14px;
                        }
                        .header-badge {
                            background: #DCFCE7;
                            color: var(--primary-dark);
                            padding: 6px 14px;
                            border-radius: 20px;
                            font-size: 13px;
                            font-weight: 700;
                            display: flex;
                            align-items: center;
                            gap: 6px;
                        }
                        .pulse-dot {
                            width: 8px;
                            height: 8px;
                            background: var(--primary-light);
                            border-radius: 50%;
                            animation: pulse 1.5s infinite;
                        }
                        @keyframes pulse {
                            0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.7); }
                            70% { transform: scale(1); box-shadow: 0 0 0 8px rgba(34, 197, 94, 0); }
                            100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(34, 197, 94, 0); }
                        }
                        .grid {
                            display: grid;
                            grid-template-columns: 1fr 1fr;
                            gap: 24px;
                            margin-bottom: 24px;
                        }
                        @media (max-width: 850px) {
                            .grid { grid-template-columns: 1fr; }
                        }
                        .card {
                            background: white;
                            border-radius: 16px;
                            padding: 24px;
                            border: 1px solid var(--border);
                            box-shadow: 0 4px 20px -2px rgba(0,0,0,0.05);
                        }
                        .card-header {
                            display: flex;
                            align-items: center;
                            gap: 10px;
                            margin-bottom: 18px;
                            padding-bottom: 12px;
                            border-bottom: 1px solid var(--border);
                        }
                        .card-header h2 {
                            font-size: 17px;
                            font-weight: 700;
                            color: var(--text);
                        }
                        label {
                            display: block;
                            font-size: 13px;
                            font-weight: 600;
                            color: var(--text-muted);
                            margin-bottom: 6px;
                        }
                        select, input {
                            width: 100%;
                            padding: 11px 14px;
                            border: 1.5px solid var(--border);
                            border-radius: 10px;
                            font-size: 14px;
                            font-family: inherit;
                            margin-bottom: 14px;
                            outline: none;
                            transition: border-color 0.2s;
                        }
                        select:focus, input:focus {
                            border-color: var(--primary);
                        }
                        .btn {
                            width: 100%;
                            padding: 12px 18px;
                            border: none;
                            border-radius: 10px;
                            font-weight: 700;
                            font-size: 14.5px;
                            cursor: pointer;
                            transition: transform 0.1s, background-color 0.2s;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            gap: 8px;
                        }
                        .btn:active { transform: scale(0.98); }
                        .btn-primary { background: var(--primary); color: white; }
                        .btn-primary:hover { background: var(--primary-dark); }
                        .btn-info { background: var(--info); color: white; }
                        .btn-info:hover { background: #0369A1; }
                        .btn-danger { background: var(--danger); color: white; }
                        .btn-danger:hover { background: #B91C1C; }
                        .chip-group {
                            display: flex;
                            gap: 8px;
                            margin-bottom: 14px;
                            flex-wrap: wrap;
                        }
                        .chip {
                            background: #F1F5F9;
                            border: 1px solid #CBD5E1;
                            padding: 6px 12px;
                            border-radius: 8px;
                            font-size: 12px;
                            font-weight: 600;
                            cursor: pointer;
                        }
                        .chip:hover {
                            background: #E2E8F0;
                            border-color: #94A3B8;
                        }
                        .table-container {
                            background: white;
                            border-radius: 16px;
                            padding: 24px;
                            border: 1px solid var(--border);
                            box-shadow: 0 4px 20px -2px rgba(0,0,0,0.05);
                            overflow-x: auto;
                        }
                        table {
                            width: 100%;
                            border-collapse: collapse;
                            text-align: left;
                            font-size: 13.5px;
                        }
                        th {
                            color: var(--text-muted);
                            font-weight: 700;
                            padding: 12px 14px;
                            border-bottom: 2px solid var(--border);
                        }
                        td {
                            padding: 12px 14px;
                            border-bottom: 1px solid var(--border);
                            vertical-align: middle;
                        }
                        .progress-bar-bg {
                            background: #E2E8F0;
                            height: 8px;
                            border-radius: 4px;
                            overflow: hidden;
                            width: 120px;
                        }
                        .progress-bar-fill {
                            height: 100%;
                            border-radius: 4px;
                            transition: width 0.3s;
                        }
                        .status-pill {
                            display: inline-block;
                            padding: 4px 10px;
                            border-radius: 12px;
                            font-size: 11px;
                            font-weight: 700;
                        }
                        .status-available { background: #DCFCE7; color: #166534; }
                        .status-almost-full { background: #FEF3C7; color: #B45309; }
                        .status-full { background: #FEE2E2; color: #991B1B; }
                        .toast {
                            padding: 12px 16px;
                            border-radius: 10px;
                            font-size: 13.5px;
                            margin-top: 14px;
                            display: none;
                        }
                        .toast-success { background: #DCFCE7; color: #166534; border: 1px solid #86EFAC; }
                        .toast-info { background: #E0F2FE; color: #0369A1; border: 1px solid #7DD3FC; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <header>
                            <div class="header-title">
                                <span style="font-size: 28px;">♻️</span>
                                <div>
                                    <h1 style="font-size: 20px; font-weight: 800;">Smart Dustbin Hardware & IoT Simulator</h1>
                                    <p style="font-size: 13px; color: var(--text-muted);">Real-time bidirectional synchronization with Greenify Mobile App & Recycler Route Map</p>
                                </div>
                            </div>
                            <div class="header-badge">
                                <div class="pulse-dot"></div>
                                Live Connected
                            </div>
                        </header>

                        <div class="grid">
                            <!-- CARD 1: Direct Scale Deposit (Simulate Citizen Dropping Plastic) -->
                            <div class="card">
                                <div class="card-header">
                                    <span style="font-size: 20px;">⚖️</span>
                                    <h2>1. Deposit Plastic Scale (Citizen Simulation)</h2>
                                </div>
                                <p style="font-size: 12.5px; color: var(--text-muted); margin-bottom: 14px;">
                                    Simulates a citizen depositing sorted plastic at a smart booth. Instantly awards tokens to citizen wallet and updates booth fill metrics.
                                </p>

                                <label>Target Smart Booth:</label>
                                <select id="depositBoothSelect"></select>

                                <label>Citizen Recycler Account:</label>
                                <select id="userSelect"></select>

                                <label>Measured Weight (kg):</label>
                                <input type="number" id="depositWeight" step="0.1" value="2.5" min="0.1">

                                <div class="chip-group">
                                    <span class="chip" onclick="setWeight(0.5)">+0.5 kg</span>
                                    <span class="chip" onclick="setWeight(1.0)">+1.0 kg</span>
                                    <span class="chip" onclick="setWeight(2.5)">+2.5 kg</span>
                                    <span class="chip" onclick="setWeight(5.0)">+5.0 kg</span>
                                    <span class="chip" onclick="setWeight(10.0)">+10.0 kg</span>
                                </div>

                                <label>Plastic Polymer Type:</label>
                                <select id="plasticType">
                                    <option value="PET Bottles (Beverage & Water)">PET Bottles (Beverage & Water)</option>
                                    <option value="HDPE Containers (Milk & Detergent)">HDPE Containers (Milk & Detergent)</option>
                                    <option value="PP Rigid Plastic">PP Rigid Plastic</option>
                                    <option value="Mixed Sorted Recyclables">Mixed Sorted Recyclables</option>
                                </select>

                                <button class="btn btn-primary" onclick="submitDeposit()">
                                    <span>⚖️</span> Weigh & Deposit Plastic
                                </button>
                                <div id="depositToast" class="toast toast-success"></div>
                            </div>

                            <!-- CARD 2: IoT Ultrasonic Level Sensor (Simulate Dustbin Fill Level) -->
                            <div class="card">
                                <div class="card-header">
                                    <span style="font-size: 20px;">📡</span>
                                    <h2>2. Ultrasonic IoT Level Sensor (Map Telemetry)</h2>
                                </div>
                                <p style="font-size: 12.5px; color: var(--text-muted); margin-bottom: 14px;">
                                    Simulates the ultrasonic depth sensor mounted on the dustbin lid. Updates the live trash percentage on the Recycler Route Map (Turns Red ≥80%).
                                </p>

                                <label>Target Smart Dustbin:</label>
                                <select id="sensorBoothSelect"></select>

                                <label>Trash Fill Percentage: <b id="fillPctLabel" style="color: var(--primary);">75%</b></label>
                                <input type="range" id="fillSlider" min="0" max="100" value="75" oninput="updateFillLabel(this.value)" style="margin-bottom: 12px;">

                                <div class="chip-group">
                                    <span class="chip" onclick="setFill(0)">0% Empty</span>
                                    <span class="chip" onclick="setFill(35)">35% Normal</span>
                                    <span class="chip" onclick="setFill(60)">60% Medium</span>
                                    <span class="chip" style="color: var(--warning); border-color: var(--warning);" onclick="setFill(85)">85% Warning</span>
                                    <span class="chip" style="color: var(--danger); border-color: var(--danger);" onclick="setFill(100)">100% Full (Red Pin)</span>
                                </div>

                                <button class="btn btn-info" onclick="submitSensorTelemetry()">
                                    <span>📡</span> Broadcast Ultrasonic Telemetry
                                </button>
                                <div id="sensorToast" class="toast toast-info"></div>

                                <hr style="margin: 20px 0; border: none; border-top: 1px solid var(--border);">

                                <div class="card-header" style="margin-bottom: 10px; padding-bottom: 8px;">
                                    <span style="font-size: 18px;">📱</span>
                                    <h3 style="font-size: 15px; font-weight: 700;">Dynamic App QR Code</h3>
                                </div>
                                <div style="display: flex; gap: 14px; align-items: center;">
                                    <button class="btn btn-primary" style="flex: 1; padding: 10px;" onclick="generateLiveQr()">
                                        Generate Dynamic QR
                                    </button>
                                </div>
                                <div id="qrDisplayArea" style="display: none; text-align: center; margin-top: 14px; padding: 14px; background: #F8FAFC; border-radius: 12px; border: 1px dashed #CBD5E1;">
                                    <img id="qrImage" src="" alt="QR" style="width: 140px; height: 140px; border-radius: 8px; margin-bottom: 8px;">
                                    <p style="font-size: 11.5px; font-family: 'JetBrains Mono', monospace; color: var(--text-muted);" id="qrTokenText"></p>
                                </div>
                            </div>
                        </div>

                        <!-- LIVE MONITOR TABLE OF DHAKA SMART BOOTHS -->
                        <div class="table-container">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                                <div>
                                    <h2 style="font-size: 17px; font-weight: 800;">Dhaka Metropolitan Smart Dustbins — Live IoT Status</h2>
                                    <p style="font-size: 12.5px; color: var(--text-muted);">Real-time telemetry synchronized with Recycler Dashboard & OpenStreetMap</p>
                                </div>
                                <button class="chip" style="background: white; border: 1.5px solid var(--primary); color: var(--primary);" onclick="loadData()">
                                    🔄 Refresh Now
                                </button>
                            </div>

                            <table>
                                <thead>
                                    <tr>
                                        <th>Code</th>
                                        <th>Location Address</th>
                                        <th>Capacity</th>
                                        <th>Current Load</th>
                                        <th>Fill Percentage</th>
                                        <th>Sensor Status</th>
                                        <th>Quick Action</th>
                                    </tr>
                                </thead>
                                <tbody id="boothsTableBody">
                                    <tr><td colspan="7" style="text-align:center; padding: 20px;">Loading live booth telemetry...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <script>
                        let boothsData = [];
                        let usersData = [];

                        async function loadData() {
                            try {
                                const res = await fetch('/api/v1/sim/status');
                                const data = await res.json();
                                boothsData = data.booths || [];
                                usersData = data.users || [];
                                renderDropdowns();
                                renderTable();
                            } catch (e) {
                                console.error('Failed to load status:', e);
                            }
                        }

                        function renderDropdowns() {
                            const depositSelect = document.getElementById('depositBoothSelect');
                            const sensorSelect = document.getElementById('sensorBoothSelect');
                            const userSelect = document.getElementById('userSelect');

                            const curDep = depositSelect.value;
                            const curSen = sensorSelect.value;
                            const curUsr = userSelect.value;

                            depositSelect.innerHTML = boothsData.map(b => `<option value="${b.boothId}">${b.boothCode} - ${b.locationAddress} (${b.currentWeightKg} kg / ${b.fillPercentage}%)</option>`).join('');
                            sensorSelect.innerHTML = boothsData.map(b => `<option value="${b.boothId}">${b.boothCode} - ${b.locationAddress}</option>`).join('');
                            userSelect.innerHTML = usersData.map(u => `<option value="${u.userId}">${u.fullName} (${u.phoneNumber}) • ${u.totalTokens} Tokens</option>`).join('');

                            if (curDep) depositSelect.value = curDep;
                            if (curSen) sensorSelect.value = curSen;
                            if (curUsr) userSelect.value = curUsr;
                        }

                        function renderTable() {
                            const tbody = document.getElementById('boothsTableBody');
                            tbody.innerHTML = boothsData.map(b => {
                                const pct = b.fillPercentage || 0;
                                let color = '#15803D';
                                let statusClass = 'status-available';
                                if (pct >= 80) {
                                    color = '#DC2626';
                                    statusClass = 'status-full';
                                } else if (pct >= 50) {
                                    color = '#D97706';
                                    statusClass = 'status-almost-full';
                                }

                                return `
                                    <tr>
                                        <td><b style="font-family: 'JetBrains Mono', monospace; color: var(--primary);">${b.boothCode}</b></td>
                                        <td style="max-width: 220px;">${b.locationAddress}</td>
                                        <td>${b.capacityKg} kg</td>
                                        <td><b>${b.currentWeightKg} kg</b></td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 8px;">
                                                <div class="progress-bar-bg">
                                                    <div class="progress-bar-fill" style="width: ${Math.min(100, pct)}%; background: ${color};"></div>
                                                </div>
                                                <span style="font-weight: 700; color: ${color}; font-size: 12px;">${pct}%</span>
                                            </div>
                                        </td>
                                        <td><span class="status-pill ${statusClass}">${b.boothStatus}</span></td>
                                        <td>
                                            <button class="chip" style="padding: 4px 8px; font-size: 11px;" onclick="emptyBooth(${b.boothId})">
                                                🧹 Empty (0 kg)
                                            </button>
                                        </td>
                                    </tr>
                                `;
                            }).join('');
                        }

                        function setWeight(w) {
                            document.getElementById('depositWeight').value = w;
                        }

                        function setFill(pct) {
                            document.getElementById('fillSlider').value = pct;
                            updateFillLabel(pct);
                        }

                        function updateFillLabel(val) {
                            document.getElementById('fillPctLabel').innerText = val + '%';
                            const label = document.getElementById('fillPctLabel');
                            if (val >= 80) label.style.color = 'var(--danger)';
                            else if (val >= 50) label.style.color = 'var(--warning)';
                            else label.style.color = 'var(--primary)';
                        }

                        async function submitDeposit() {
                            const boothId = document.getElementById('depositBoothSelect').value;
                            const userId = document.getElementById('userSelect').value;
                            const weightKg = parseFloat(document.getElementById('depositWeight').value);
                            const plasticType = document.getElementById('plasticType').value;

                            const res = await fetch('/api/v1/sim/deposit', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ boothId, userId, weightKg, plasticType })
                            });
                            const data = await res.json();
                            const toast = document.getElementById('depositToast');
                            toast.style.display = 'block';
                            if (data.success) {
                                toast.innerHTML = `✅ <b>Deposit Successful!</b> Deposited ${weightKg} kg ${plasticType}. Rewarded <b>+${data.tokensEarned} Tokens</b> to ${data.citizenName}!`;
                                toast.className = 'toast toast-success';
                            } else {
                                toast.innerHTML = `❌ Error: ${data.message || 'Deposit failed'}`;
                                toast.className = 'toast toast-danger';
                            }
                            await loadData();
                            setTimeout(() => { toast.style.display = 'none'; }, 6000);
                        }

                        async function submitSensorTelemetry() {
                            const boothId = document.getElementById('sensorBoothSelect').value;
                            const fillPercentage = parseFloat(document.getElementById('fillSlider').value);

                            const res = await fetch('/api/v1/sim/set-fill-level', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ boothId, fillPercentage })
                            });
                            const data = await res.json();
                            const toast = document.getElementById('sensorToast');
                            toast.style.display = 'block';
                            toast.innerHTML = `📡 <b>Sensor Telemetry Sent!</b> Dustbin ${data.boothCode} updated to <b>${fillPercentage}% (${data.currentWeightKg} kg)</b>. Status: <b>${data.boothStatus}</b>.`;
                            await loadData();
                            setTimeout(() => { toast.style.display = 'none'; }, 5000);
                        }

                        async function emptyBooth(boothId) {
                            await fetch('/api/v1/sim/empty-booth', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ boothId })
                            });
                            await loadData();
                        }

                        async function generateLiveQr() {
                            const boothId = document.getElementById('sensorBoothSelect').value;
                            const res = await fetch('/api/v1/sim/generate-qr', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ boothId })
                            });
                            const data = await res.json();
                            if (data.qrToken) {
                                const area = document.getElementById('qrDisplayArea');
                                area.style.display = 'block';
                                const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${encodeURIComponent(data.qrToken)}`;
                                document.getElementById('qrImage').src = qrUrl;
                                document.getElementById('qrTokenText').innerText = `Token: ${data.qrToken} (TTL: 60s)`;
                            }
                        }

                        // Poll every 3 seconds for live synchronization
                        loadData();
                        setInterval(loadData, 3000);
                    </script>
                </body>
                </html>
                """;

        return ResponseEntity.ok(html);
    }

    @GetMapping("/status")
    public ResponseEntity<?> getSimulatorStatus() {
        List<SmartBooth> booths = boothRepository.findAll();
        List<Map<String, Object>> boothList = new ArrayList<>();
        for (SmartBooth b : booths) {
            BigDecimal current = b.getCurrentWeightKg() != null ? b.getCurrentWeightKg() : BigDecimal.ZERO;
            BigDecimal capacity = b.getCapacityKg() != null ? b.getCapacityKg() : BigDecimal.valueOf(100.0);
            double pct = capacity.compareTo(BigDecimal.ZERO) > 0
                    ? current.divide(capacity, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).doubleValue()
                    : 0.0;

            Map<String, Object> map = new LinkedHashMap<>();
            map.put("boothId", b.getBoothId());
            map.put("boothCode", b.getBoothCode());
            map.put("locationAddress", b.getLocationAddress());
            map.put("latitude", b.getLatitude());
            map.put("longitude", b.getLongitude());
            map.put("capacityKg", capacity);
            map.put("currentWeightKg", current.setScale(1, RoundingMode.HALF_UP));
            map.put("fillPercentage", Math.round(pct * 10.0) / 10.0);
            map.put("boothStatus", b.getBoothStatus());
            boothList.add(map);
        }

        List<User> users = userRepository.findAll().stream()
                .filter(u -> u.getRole() == Role.USER)
                .toList();
        List<Map<String, Object>> userList = new ArrayList<>();
        for (User u : users) {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("userId", u.getUserId());
            map.put("fullName", u.getFullName());
            map.put("phoneNumber", u.getPhoneNumber());
            map.put("totalTokens", u.getTotalTokens());
            userList.add(map);
        }

        return ResponseEntity.ok(Map.of(
                "booths", boothList,
                "users", userList
        ));
    }

    @PostMapping("/deposit")
    public ResponseEntity<?> simulateDeposit(@RequestBody Map<String, Object> body) {
        Long boothId = Long.valueOf(body.get("boothId").toString());
        Long userId = body.containsKey("userId") && body.get("userId") != null
                ? Long.valueOf(body.get("userId").toString())
                : null;
        BigDecimal weightKg = new BigDecimal(body.get("weightKg").toString());
        String plasticType = body.containsKey("plasticType") ? body.get("plasticType").toString() : "PET/Mix";

        PlasticDeposit deposit = depositService.directSimulatedDeposit(boothId, userId, weightKg, plasticType);
        User user = deposit.getUser();

        return ResponseEntity.ok(Map.of(
                "success", true,
                "depositId", deposit.getDepositId(),
                "weightKg", deposit.getPlasticWeightKg(),
                "tokensEarned", deposit.getTokensEarned(),
                "citizenName", user.getFullName(),
                "userNewTokenBalance", user.getTotalTokens(),
                "boothCode", deposit.getBooth().getBoothCode(),
                "boothNewWeightKg", deposit.getBooth().getCurrentWeightKg(),
                "boothStatus", deposit.getBooth().getBoothStatus()
        ));
    }

    @PostMapping("/set-fill-level")
    public ResponseEntity<?> setFillLevel(@RequestBody Map<String, Object> body) {
        Long boothId = Long.valueOf(body.get("boothId").toString());
        double fillPercentage = Double.parseDouble(body.get("fillPercentage").toString());

        SmartBooth updated = depositService.setBoothFillPercentage(boothId, fillPercentage);

        return ResponseEntity.ok(Map.of(
                "success", true,
                "boothId", updated.getBoothId(),
                "boothCode", updated.getBoothCode(),
                "currentWeightKg", updated.getCurrentWeightKg(),
                "boothStatus", updated.getBoothStatus()
        ));
    }

    @PostMapping("/empty-booth")
    public ResponseEntity<?> emptyBooth(@RequestBody Map<String, Object> body) {
        Long boothId = Long.valueOf(body.get("boothId").toString());
        SmartBooth updated = depositService.emptyBooth(boothId);

        return ResponseEntity.ok(Map.of(
                "success", true,
                "boothId", updated.getBoothId(),
                "boothCode", updated.getBoothCode(),
                "currentWeightKg", BigDecimal.ZERO,
                "boothStatus", "Available"
        ));
    }

    @PostMapping("/generate-qr")
    public ResponseEntity<?> generateQr(@RequestBody Map<String, Object> body) {
        Long boothId = Long.valueOf(body.get("boothId").toString());
        String qrToken = depositService.generateBoothQrToken(boothId);

        return ResponseEntity.ok(Map.of(
                "success", true,
                "boothId", boothId,
                "qrToken", qrToken,
                "ttlSeconds", 60
        ));
    }
}
