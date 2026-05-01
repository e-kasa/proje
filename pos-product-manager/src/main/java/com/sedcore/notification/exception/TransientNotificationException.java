package com.sedcore.notification.exception;

/**
 * Sprint 25 — Geçici hata: SMTP timeout, network glitch, provider 5xx.
 * {@code @Retryable} bu exception'ı yakalayınca yeniden dener.
 */
public class TransientNotificationException extends RuntimeException {

    public TransientNotificationException(String message) {
        super(message);
    }

    public TransientNotificationException(String message, Throwable cause) {
        super(message, cause);
    }
}
