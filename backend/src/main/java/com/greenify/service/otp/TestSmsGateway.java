package com.greenify.service.otp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@ConditionalOnProperty(name = "otp.provider", havingValue = "mock", matchIfMissing = true)
public class TestSmsGateway implements SmsGateway {

    @Override
    public boolean sendSms(String phoneNumber, String message) {
        log.info("[TEST SMS GATEWAY] Mock sending SMS to {}: {}", phoneNumber, message);
        return true;
    }
}
