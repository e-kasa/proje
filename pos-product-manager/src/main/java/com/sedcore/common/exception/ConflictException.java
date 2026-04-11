package com.sedcore.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Tekrar eden kayıt / çakışma durumlarında fırlatılır → HTTP 409
 * <pre>
 *   throw new ConflictException("Bu SKU zaten kayıtlı: SKU-001");
 * </pre>
 */
@ResponseStatus(HttpStatus.CONFLICT)
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
