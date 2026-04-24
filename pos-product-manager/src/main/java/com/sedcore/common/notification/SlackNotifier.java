package com.sedcore.common.notification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Minimal Slack incoming webhook notifier.
 *
 * Config (application.properties):
 *   slack.webhook.url=https://hooks.slack.com/services/XXX/YYY/ZZZ
 *
 * webhook URL boşsa notify() no-op — dev/local'de hata atmaz, sadece log basar.
 */
@Component
@Slf4j
public class SlackNotifier {

    private final String webhookUrl;
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    public SlackNotifier(@Value("${slack.webhook.url:}") String webhookUrl) {
        this.webhookUrl = webhookUrl;
    }

    public boolean isConfigured() {
        return webhookUrl != null && !webhookUrl.isBlank();
    }

    public void notify(String text) {
        if (!isConfigured()) {
            log.debug("Slack webhook yapilandirilmamis — mesaj atlanacak: {}", text);
            return;
        }
        try {
            String body = "{\"text\":\"" + escapeJson(text) + "\"}";
            HttpRequest req = HttpRequest.newBuilder(URI.create(webhookUrl))
                    .header("Content-Type", "application/json")
                    .timeout(Duration.ofSeconds(10))
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();
            HttpResponse<String> res = client.send(req, HttpResponse.BodyHandlers.ofString());
            if (res.statusCode() >= 200 && res.statusCode() < 300) {
                log.info("Slack webhook gonderildi: status={}", res.statusCode());
            } else {
                log.warn("Slack webhook basarisiz: status={}, body={}", res.statusCode(), res.body());
            }
        } catch (Exception e) {
            log.warn("Slack webhook exception: {}", e.getMessage());
        }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
