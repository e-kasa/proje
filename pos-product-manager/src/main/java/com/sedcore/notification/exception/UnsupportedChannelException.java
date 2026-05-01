package com.sedcore.notification.exception;

/**
 * Sprint 25 — Henüz desteklenmeyen kanal (SMS Sprint 26, WhatsApp Sprint 27,
 * Push Sprint 28).
 */
public class UnsupportedChannelException extends PermanentNotificationException {

    public UnsupportedChannelException(String message) {
        super(message);
    }
}
