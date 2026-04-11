package com.sedcore.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * OperationNotAllowedException - Thrown when an operation cannot be performed in current state
 * Returns HTTP 403 Forbidden
 *
 * Examples:
 *   - Cannot return a cancelled sale
 *   - Cannot modify a completed transaction
 *   - Cannot delete a product with active sales
 *   - Insufficient permissions for operation
 */
@ResponseStatus(HttpStatus.FORBIDDEN)
public class OperationNotAllowedException extends RuntimeException {
    private String operation;
    private String reason;

    public OperationNotAllowedException(String message) {
        super(message);
    }

    public OperationNotAllowedException(String message, String operation, String reason) {
        super(message);
        this.operation = operation;
        this.reason = reason;
    }

    public OperationNotAllowedException(String message, Throwable cause) {
        super(message, cause);
    }

    public String getOperation() {
        return operation;
    }

    public String getReason() {
        return reason;
    }
}
