package com.sedcore.common.util;

import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.EmptyResultDataAccessException;

/**
 * Exception Mapper - Sistem'deki her exception'ı uygun TMessageType hata koduna harita eder
 *
 * Hata Kodu Kategorileri:
 * - 1001-1099: Doğrulama Hataları (Validation)
 * - 1300-1399: Stok/Depo Hataları (Inventory)
 * - 1400-1499: Ödeme Hataları (Payment)
 * - 9998: Sonuç Bulunamadı (No Results)
 * - 9999: Beklenmeyen Hata (Unexpected Error)
 */
@Slf4j
public class ExceptionMapper {

    /**
     * RuntimeException'ı uygun TMessageType'a dönüştür
     */
    public static TOpenException mapException(Exception e) {
        return new TOpenException(new TOpenMessage(getMessageType(e)));
    }

    /**
     * Exception tipi ve mesajına göre uygun TMessageType'ı döndür.
     * Java 25 — Pattern Matching switch expression kullanır.
     */
    public static TMessageType getMessageType(Exception e) {
        if (e == null) return TMessageType.UNEXPECTED_ERROR_9999;

        // Java 25: Pattern matching switch — önce exception tipine bak
        TMessageType byType = switch (e) {
            case EmptyResultDataAccessException ex  -> TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
            case DataIntegrityViolationException ex -> TMessageType.ALREADY_EXISTS_1004;
            default                                 -> null;
        };
        if (byType != null) return byType;

        // Mesaj içeriğine göre eşleştir
        String msg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";

        if (msg.contains("bulunamad") || msg.contains("not found") || msg.contains("could not find")
                || msg.contains("no result") || msg.contains("sonuç bulunamadı")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }
        if (msg.contains("already exists") || msg.contains("zaten var") || msg.contains("duplicate")) {
            return TMessageType.ALREADY_EXISTS_1004;
        }
        if (msg.contains("required") || msg.contains("gerekli") || msg.contains("amount") || msg.contains("tutarı")) {
            return TMessageType.FIELD_IS_REQUIRED_1001;
        }
        if (msg.contains("between") || msg.contains("arasında")) {
            return TMessageType.BETWEEN_MIN_AND_MAX_1002;
        }
        if (msg.contains("minimum") || msg.contains("min_size")) {
            return TMessageType.VALIDATION_MIN_SIZE_1032;
        }
        if (msg.contains("maximum") || msg.contains("max_size")) {
            return TMessageType.VALIDATION_MAX_SIZE_1033;
        }
        if (msg.contains("format") || msg.contains("invalid") || msg.contains("insufficient")
                || msg.contains("yetersiz stok")) {
            return TMessageType.ENTERED_DATA_IS_NOT_IN_FORMAT_1046;
        }
        if (msg.contains("unauthorized") || msg.contains("yetki")) {
            return TMessageType.NOT_AUTHORIZED_1012;
        }
        if (msg.contains("cannot change") || msg.contains("değiştiremez")) {
            return TMessageType.SAME_AS_DB_CAN_NOT_UPDATE_1050;
        }

        log.warn("Unmapped exception: {} - {}", e.getClass().getSimpleName(), msg);
        return TMessageType.UNEXPECTED_ERROR_9999;
    }

    /**
     * Exception'ı logla ve TOpenException'a dönüştür
     */
    public static TOpenException mapAndLog(Exception e, String operation) {
        TMessageType messageType = getMessageType(e);
        log.error("Error during [{}]: {} [Code: {}]", operation, e.getMessage(), messageType.getCode(), e);
        return new TOpenException(new TOpenMessage(messageType));
    }

    /**
     * Parametre olmadan - generic error
     */
    public static TOpenException map(Exception e) {
        return mapAndLog(e, "Operation");
    }

    /**
     * Not Found veya boş result dönüş durumu
     */
    public static TOpenException notFound(String resource) {
        log.warn("Resource not found: {}", resource);
        return new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006));
    }

    /**
     * Duplicate entry hatası
     */
    public static TOpenException duplicateEntry(String resource) {
        log.warn("Duplicate entry: {}", resource);
        return new TOpenException(new TOpenMessage(TMessageType.ALREADY_EXISTS_1004));
    }

    /**
     * Validation hatası
     */
    public static TOpenException validationError(String field, String reason) {
        log.warn("Validation error - Field: {}, Reason: {}", field, reason);
        return new TOpenException(new TOpenMessage(TMessageType.ENTERED_DATA_IS_NOT_IN_FORMAT_1046));
    }

    /**
     * Authorization hatası
     */
    public static TOpenException unauthorized() {
        log.warn("Unauthorized operation");
        return new TOpenException(new TOpenMessage(TMessageType.NOT_AUTHORIZED_1012));
    }

    /**
     * Insufficient inventory hatası
     */
    public static TOpenException insufficientInventory(String productId, int available, int requested) {
        log.warn("Insufficient inventory - Product: {}, Available: {}, Requested: {}",
                productId, available, requested);
        return new TOpenException(new TOpenMessage(TMessageType.ENTERED_DATA_IS_NOT_IN_FORMAT_1046));
    }
}
