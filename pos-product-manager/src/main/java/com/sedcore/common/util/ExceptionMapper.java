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
     * Exception tipi ve mesajına göre uygun TMessageType'ı döndür
     */
    public static TMessageType getMessageType(Exception e) {
        if (e == null) {
            return TMessageType.UNEXPECTED_ERROR_9999;
        }

        String message = e.getMessage() != null ? e.getMessage().toLowerCase() : "";
        String exceptionType = e.getClass().getSimpleName().toLowerCase();

        // NULL_POINTER veya kayıt bulunamadı
        if (e instanceof EmptyResultDataAccessException ||
            message.contains("bulunamad") ||
            message.contains("not found") ||
            message.contains("could not find")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }

        // DUPLICATE veya zaten var
        if (e instanceof DataIntegrityViolationException ||
            message.contains("already exists") ||
            message.contains("zaten var") ||
            message.contains("duplicate")) {
            return TMessageType.ALREADY_EXISTS_1004;
        }

        // VALIDATION HATALARI
        if (message.contains("required") || message.contains("gerekli")) {
            return TMessageType.FIELD_IS_REQUIRED_1001;
        }

        if (message.contains("between") || message.contains("arasında")) {
            return TMessageType.BETWEEN_MIN_AND_MAX_1002;
        }

        if (message.contains("minimum") || message.contains("min_size")) {
            return TMessageType.VALIDATION_MIN_SIZE_1032;
        }

        if (message.contains("maximum") || message.contains("max_size")) {
            return TMessageType.VALIDATION_MAX_SIZE_1033;
        }

        if (message.contains("format") || message.contains("invalid")) {
            return TMessageType.ENTERED_DATA_IS_NOT_IN_FORMAT_1046;
        }

        // STOK HATALARI
        if (message.contains("insufficient") || message.contains("yetersiz stok")) {
            return TMessageType.ENTERED_DATA_IS_NOT_IN_FORMAT_1046; // Custom: 1300 alt grubu
        }

        if (message.contains("warehouse") || message.contains("depo")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }

        if (message.contains("product") || message.contains("ürün")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }

        // MÜŞTERI/TEDARIKÇI HATALARI
        if (message.contains("customer") || message.contains("müşteri")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }

        if (message.contains("supplier") || message.contains("tedarikçi")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }

        // ÖDEME HATALARI
        if (message.contains("payment") || message.contains("ödeme")) {
            return TMessageType.UNEXPECTED_ERROR_9999;
        }

        if (message.contains("amount") || message.contains("tutarı")) {
            return TMessageType.FIELD_IS_REQUIRED_1001;
        }

        // YETKİ HATALARI
        if (message.contains("unauthorized") || message.contains("yetki")) {
            return TMessageType.NOT_AUTHORIZED_1012;
        }

        if (message.contains("cannot change") || message.contains("değiştiremez")) {
            return TMessageType.SAME_AS_DB_CAN_NOT_UPDATE_1050;
        }

        // GENEL HATA PATTERNS
        if (message.contains("no result") || message.contains("sonuç bulunamadı")) {
            return TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006;
        }

        // DEFAULT: Beklenmeyen hata
        log.warn("Unmapped exception: {} - {}", exceptionType, message);
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
