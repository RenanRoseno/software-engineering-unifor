package com.hospital.contracts;

public record ApiErrorResponse(
    String code,
    String message,
    String path,
    long timestamp
) {
}
