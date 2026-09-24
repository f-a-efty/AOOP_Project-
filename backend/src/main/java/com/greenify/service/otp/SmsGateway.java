package com.greenify.service.otp;

public interface SmsGateway {
    boolean sendSms(String phoneNumber, String message);
}
