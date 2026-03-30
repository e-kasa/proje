package com.sedcore.exception;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Uygulama genelinde merkezi hata yönetimi.
 *
 * NOT: core kütüphanesinde 'globalExceptionHandler' bean adı zaten mevcut
 * olduğu için bu sınıf 'appExceptionHandler' adıyla kayıtlıdır.
 *
 * Her hata → ApiErrorResponse olarak döner.
 * Frontend bu yapıyı alıp sağ üstte zamanlı toast/popup gösterir.
 *
 * Toast renk rehberi (frontend için):
 *   4xx → kırmızı / turuncu
 *   5xx → koyu kırmızı
 *   süre → 4-5 saniye
 */
@RestControllerAdvice
@Slf4j
public class AppExceptionHandler {

    // ====================================================================
    // 1. ÖZEL İŞ KURALI HATALARI
    // ====================================================================

    /** Kayıt bulunamadı → 404 */
    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNotFound(
            NotFoundException ex, HttpServletRequest request) {

        log.warn("[404] {}", ex.getMessage());

        return build(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage(), request);
    }

    /** İş kuralı ihlali (stok yetersiz, limit aşımı vb.) → 422 */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiErrorResponse> handleBusiness(
            BusinessException ex, HttpServletRequest request) {

        log.warn("[422] {}", ex.getMessage());

        return build(HttpStatus.UNPROCESSABLE_ENTITY, "BUSINESS_RULE_VIOLATION",
                ex.getMessage(), request);
    }

    /** Mükerrer kayıt / çakışma → 409 */
    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ApiErrorResponse> handleConflict(
            ConflictException ex, HttpServletRequest request) {

        log.warn("[409] {}", ex.getMessage());

        return build(HttpStatus.CONFLICT, "CONFLICT", ex.getMessage(), request);
    }

    // ====================================================================
    // 2. VALIDATION HATALARI (@Valid / @Validated)
    // ====================================================================

    /** DTO alanı validation hatası → 400, tüm alanlar details'a eklenir */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest request) {

        BindingResult result = ex.getBindingResult();

        List<ApiErrorResponse.FieldError> details = result.getFieldErrors()
                .stream()
                .map(fe -> ApiErrorResponse.FieldError.builder()
                        .field(fe.getField())
                        .message(fe.getDefaultMessage())
                        .rejectedValue(fe.getRejectedValue())
                        .build())
                .collect(Collectors.toList());

        log.warn("[400] Validation hatasi - {} alan(lar) geçersiz", details.size());

        ApiErrorResponse body = ApiErrorResponse.builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .error("VALIDATION_ERROR")
                .message("Gönderilen veriler geçersiz. Lütfen alanları kontrol edin.")
                .path(request.getRequestURI())
                .timestamp(LocalDateTime.now())
                .details(details)
                .build();

        return ResponseEntity.badRequest().body(body);
    }

    // ====================================================================
    // 3. HTTP / SERVLET HATALARI
    // ====================================================================

    /** Endpoint bulunamadı → 404 (Spring 6 öncesi) */
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNoHandler(
            NoHandlerFoundException ex, HttpServletRequest request) {
        log.warn("[404] Handler bulunamadi: {}", request.getRequestURI());
        return build(HttpStatus.NOT_FOUND, "NOT_FOUND",
                "Endpoint bulunamadi: " + request.getRequestURI(), request);
    }

    /** Endpoint bulunamadı → 404 (Spring 6.1+) */
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleNoResource(
            NoResourceFoundException ex, HttpServletRequest request) {
        log.warn("[404] Kaynak bulunamadi: {}", request.getRequestURI());
        return build(HttpStatus.NOT_FOUND, "NOT_FOUND",
                "Endpoint bulunamadi: " + request.getRequestURI(), request);
    }

    /** Request body parse edilemedi (malformed JSON vb.) → 400 */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiErrorResponse> handleUnreadable(
            HttpMessageNotReadableException ex, HttpServletRequest request) {

        log.warn("[400] Okunamayan istek gövdesi: {}", ex.getMessage());

        return build(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST",
                "İstek gövdesi okunamadı. JSON formatını kontrol edin.", request);
    }

    /** Zorunlu query parametresi eksik → 400 */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiErrorResponse> handleMissingParam(
            MissingServletRequestParameterException ex, HttpServletRequest request) {

        String msg = "Zorunlu parametre eksik: '" + ex.getParameterName() + "'";
        log.warn("[400] {}", msg);

        return build(HttpStatus.BAD_REQUEST, "MISSING_PARAMETER", msg, request);
    }

    /** Parametre tipi uyuşmazlığı (String yerine Integer vb.) → 400 */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiErrorResponse> handleTypeMismatch(
            MethodArgumentTypeMismatchException ex, HttpServletRequest request) {

        String msg = String.format("'%s' parametresi geçersiz değer: '%s'",
                ex.getName(), ex.getValue());
        log.warn("[400] {}", msg);

        return build(HttpStatus.BAD_REQUEST, "TYPE_MISMATCH", msg, request);
    }

    // ====================================================================
    // 4. VERİTABANI HATALARI
    // ====================================================================

    /** Unique constraint, FK ihlali vb. → 409 */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiErrorResponse> handleDataIntegrity(
            DataIntegrityViolationException ex, HttpServletRequest request) {

        log.error("[409] Veri bütünlüğü hatası: {}", ex.getMostSpecificCause().getMessage());

        return build(HttpStatus.CONFLICT, "DATA_INTEGRITY_VIOLATION",
                "Bu kayıt zaten mevcut veya başka kayıtlarla ilişkili.", request);
    }

    // ====================================================================
    // 5. GENEL / BEKLENMEDİK HATALAR
    // ====================================================================

    /**
     * Yukarıdakilerin hiçbiriyle eşleşmeyen RuntimeException → 500
     * (SaleServiceIntegrated içindeki RuntimeException throw'lar buraya düşer
     *  özel exception'lara migrate edilene kadar)
     */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiErrorResponse> handleRuntime(
            RuntimeException ex, HttpServletRequest request) {

        log.error("[500] RuntimeException: {}", ex.getMessage(), ex);

        return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                ex.getMessage() != null ? ex.getMessage() : "Beklenmedik bir hata oluştu.",
                request);
    }

    /** Hiç yakalanmayan her şey → 500 */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleAll(
            Exception ex, HttpServletRequest request) {

        log.error("[500] Bilinmeyen hata: {}", ex.getMessage(), ex);

        return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Sunucu tarafında beklenmedik bir hata oluştu.", request);
    }

    // ====================================================================
    // YARDIMCI METOD
    // ====================================================================

    private ResponseEntity<ApiErrorResponse> build(HttpStatus status, String error,
                                                    String message, HttpServletRequest request) {
        ApiErrorResponse body = ApiErrorResponse.builder()
                .status(status.value())
                .error(error)
                .message(message)
                .path(request.getRequestURI())
                .timestamp(LocalDateTime.now())
                .details(List.of())
                .build();

        return ResponseEntity.status(status).body(body);
    }
}
