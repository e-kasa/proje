package com.sedcore.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Kayıt bulunamadığında fırlatılır → HTTP 404
 * <pre>
 *   throw new NotFoundException("Ürün bulunamadı: " + id);
 * </pre>
 */
@ResponseStatus(HttpStatus.NOT_FOUND)
public class NotFoundException extends RuntimeException {

    public NotFoundException(String message) {
        super(message);
    }

    public NotFoundException(String entity, String id) {
        super(entity + " bulunamadı: " + id);
    }
}
