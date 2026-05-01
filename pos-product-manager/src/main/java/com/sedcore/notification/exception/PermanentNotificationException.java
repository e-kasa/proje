package com.sedcore.notification.exception;

/**
 * Sprint 25 — Kalıcı hata: invalid email, blacklisted recipient, provider 4xx.
 * Retry edilmez; status doğrudan FAILED'a düşer.
 */
public class PermanentNotificationException extends RuntimeException {

    public PermanentNotificationException(String message) {
        super(message);
    }

    public PermanentNotificationException(String message, Throwable cause) {
        super(message, cause);
    }
}
