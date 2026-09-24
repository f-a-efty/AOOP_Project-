package com.greenify.domain.enums;

public enum TxType {
    DEPOSIT_CREDIT("Deposit Credit"),
    CASHBACK_WITHDRAWAL("Cashback Withdrawal"),
    COUPON_PURCHASE("Coupon Purchase"),
    ADJUSTMENT("Adjustment");

    private final String displayName;

    TxType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
