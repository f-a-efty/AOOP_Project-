package com.greenify.domain.enums;

public enum PickupStatus {
    Pending,
    Accepted,
    Vehicle_Assigned,
    On_Pickup,
    Completed,
    Cancelled;

    public String getValue() {
        return name().replace("_", " ");
    }
}
