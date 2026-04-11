package com.sedcore.common.exception;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Tüm endpoint'lerden dönen standart hata yanıtı.
 *
 * Frontend bu yapıyı alıp sağ üstte zamanlı bir toast/popup olarak gösterir.
 *
 * Örnek JSON:
 * {
 *   "status"    : 404,
 *   "error"     : "NOT_FOUND",
 *   "message"   : "Ürün bulunamadı: PRD-001",
 *   "path"      : "/api/products/PRD-001",
 *   "timestamp" : "2026-03-14T10:30:00",
 *   "details"   : []
 * }
 */
@Getter
@Builder
public class ApiErrorResponse {

    /** HTTP durum kodu (400, 404, 409, 422, 500 …) */
    private int status;

    /** Kısa hata kodu — frontend'de icon/renk seçimi için kullanılır */
    private String error;

    /** Kullanıcıya gösterilecek okunabilir mesaj */
    private String message;

    /** Hata oluşan endpoint yolu */
    private String path;

    /** Sunucu saati */
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime timestamp;

    /**
     * Validation hataları gibi birden fazla detay olduğunda dolar,
     * aksi hâlde boş liste döner.
     */
    private List<FieldError> details;

    // ----------------------------------------------------------------

    @Getter
    @Builder
    public static class FieldError {
        private String field;
        private String message;
        private Object rejectedValue;
    }
}
