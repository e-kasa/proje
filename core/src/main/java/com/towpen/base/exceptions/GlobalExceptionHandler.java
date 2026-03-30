package com.towpen.base.exceptions;

import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.rest.ApiErrorBeanController;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.crossstore.ChangeSetPersister;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@RestControllerAdvice
@Slf4j
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private final ApiErrorBeanController apiErrorBeanController;

    @ExceptionHandler(TOpenException.class)
    public ResponseEntity<ApiResponse<Void>> handleTOpenException(TOpenException ex) {
        log.error("TOpenException: {}", ex.getMessages());
        HttpStatus status = isAuthenticationError(ex) ? HttpStatus.UNAUTHORIZED : HttpStatus.BAD_REQUEST;
        String message = apiErrorBeanController.convertToApiMessagesToText(ex.getMessages());
        return ResponseEntity
                .status(status)
                .body(ApiResponse.error(message));
    }

    private boolean isAuthenticationError(TOpenException ex) {
        Set<String> authErrorCodes = Set.of(
                TMessageType.USERNAME_PASSWORD_REQUIRED_1009.getCode(),
                TMessageType.USERNAME_PASSWORD_ERROR_1010.getCode(),
                TMessageType.USERNAME_CANNOT_LOGIN_1011.getCode(),
                TMessageType.DONT_MATCH_IP_ADDRESS_1034.getCode()
        );
        return ex.getMessages().stream()
                .anyMatch(m -> authErrorCodes.contains(m.getMessageCode()));
    }

    @ExceptionHandler(ChangeSetPersister.NotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNotFoundException(ChangeSetPersister.NotFoundException ex) {
        log.error("Not Found Exception: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<ApiResponse<Void>> handleBadRequestException(BadRequestException ex) {
        log.error("Bad Request Exception: {}", ex.getMessage());
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidationExceptions(
            MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        log.error("Validation Exception: {}", errors);
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error("Validation hatası"+ errors));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGlobalException(Exception ex) {
        log.error("Unexpected Exception: ", ex);
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Beklenmeyen bir hata oluştu: " + ex.getMessage()));
    }
}