package com.sedcore.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * DataConflictException - Thrown when data conflict occurs (e.g., duplicate keys, unique constraint violations)
 * Returns HTTP 409 Conflict
 *
 * Examples:
 *   - Duplicate product SKU
 *   - Duplicate sale number
 *   - Constraint violation
 */
@ResponseStatus(HttpStatus.CONFLICT)
public class DataConflictException extends RuntimeException {
    private String conflictField;
    private Object existingValue;

    public DataConflictException(String message) {
        super(message);
    }

    public DataConflictException(String message, String conflictField) {
        super(message);
        this.conflictField = conflictField;
    }

    public DataConflictException(String message, String conflictField, Object existingValue) {
        super(message);
        this.conflictField = conflictField;
        this.existingValue = existingValue;
    }

    public String getConflictField() {
        return conflictField;
    }

    public Object getExistingValue() {
        return existingValue;
    }
}
