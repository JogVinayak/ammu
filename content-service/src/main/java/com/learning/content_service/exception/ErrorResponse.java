package com.learning.content_service.exception;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ErrorResponse {
    private String error;
    private String message;
    private String traceId;

    public ErrorResponse(String error, String message, String traceId) {
        this.error = error;
        this.message = message;
        this.traceId = traceId;
    }
}
