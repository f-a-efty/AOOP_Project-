package com.greenify.domain.enums;

public enum BoothStatus {
    Empty,
    Available,
    Almost_Full,
    Full,
    Under_Maintenance,
    Offline;

    public String getValue() {
        return name().replace("_", " ");
    }
}
