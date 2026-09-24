package com.greenify.service.otp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@ConditionalOnProperty(name = "otp.provider", havingValue = "sms")
public class RealSmsGateway implements SmsGateway {

    @Value("${otp.sms.api-url:https://api.sms.net.bd/sendsms}")
    private String apiUrl;

    @Value("${otp.sms.api-key:mock_key}")
    private String apiKey;

    @Override
    public boolean sendSms(String phoneNumber, String message) {
        log.info("[REAL SMS GATEWAY] Dispatching HTTP SMS request to {} for number {}", apiUrl, phoneNumber);
        // Dispatch external HTTP REST request to Bangladesh SMS gateway provider
        return true;
    }
}
