package com.sedcore.notification.service.channel.sms;

import com.sedcore.notification.exception.PermanentNotificationException;
import com.sedcore.notification.exception.TransientNotificationException;
import com.twilio.Twilio;
import com.twilio.exception.ApiException;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Sprint 26-A — Twilio SMS provider.
 *
 * <p>Aktivasyon: {@code notification.sms.provider=twilio} +
 * {@code notification.twilio.account-sid}, {@code .auth-token}, {@code .from-phone}
 * doldurulmalı.
 *
 * <p>Hata mapping:
 * <ul>
 *   <li>Twilio 4xx (invalid number, blocked, vb.) → {@link PermanentNotificationException}
 *   <li>Twilio 5xx, network timeout → {@link TransientNotificationException}
 * </ul>
 *
 * <p>Sprint 27'de gerçek Twilio account ile devreye girer. Şu an credentials
 * yokken bean oluşmaz ({@code @ConditionalOnProperty}), {@link NoopSmsProvider}
 * default seçilir.
 */
@Component
@ConditionalOnProperty(name = "notification.sms.provider", havingValue = "twilio")
@Slf4j
public class TwilioSmsProvider implements SmsProvider {

    @Value("${notification.twilio.account-sid:}")
    private String accountSid;

    @Value("${notification.twilio.auth-token:}")
    private String authToken;

    @Value("${notification.twilio.from-phone:}")
    private String fromPhone;

    @PostConstruct
    void init() {
        if (accountSid == null || accountSid.isBlank()
                || authToken == null || authToken.isBlank()
                || fromPhone == null || fromPhone.isBlank()) {
            throw new IllegalStateException(
                    "notification.sms.provider=twilio ama credentials eksik. "
                            + "notification.twilio.{account-sid,auth-token,from-phone} doldurun.");
        }
        Twilio.init(accountSid, authToken);
        log.info("Twilio SMS provider başlatıldı. fromPhone={}", fromPhone);
    }

    @Override
    public String sendSms(String to, String body) {
        try {
            Message msg = Message.creator(
                    new PhoneNumber(to),
                    new PhoneNumber(fromPhone),
                    body
            ).create();
            log.info("Twilio SMS gönderildi. to={}, sid={}", to, msg.getSid());
            return msg.getSid();
        } catch (ApiException e) {
            int status = e.getStatusCode() != null ? e.getStatusCode() : 0;
            if (status >= 400 && status < 500) {
                throw new PermanentNotificationException(
                        "Twilio 4xx (" + status + "): " + e.getMessage(), e);
            }
            throw new TransientNotificationException(
                    "Twilio " + status + " / network: " + e.getMessage(), e);
        } catch (RuntimeException e) {
            // SDK içi network/timeout exceptionları → transient
            throw new TransientNotificationException(
                    "Twilio runtime: " + e.getClass().getSimpleName() + " " + e.getMessage(), e);
        }
    }

    @Override
    public String providerName() {
        return "twilio";
    }
}
