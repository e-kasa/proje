package com.sedcore.common.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * İş kuralı ihlallerinde fırlatılır → HTTP 422 Unprocessable Entity
 * <pre>
 *   throw new BusinessException("Kredi limiti yetersiz! Kullanılabilir: 500 TL");
 *   throw new BusinessException("Stok yetersiz! Mevcut: 3, İstenen: 10");
 * </pre>
 */
@ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
