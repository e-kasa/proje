---
title: Integration — Slack Webhook
type: synthesis
source: .claude/wiki/integrations/slack-webhook.md
ingested: 2026-04-25
last-verified: 2026-04-25
migrated-from: .claude/wiki/
---

# Slack Webhook

## Amaç

Kritik olaylar için Slack kanalına incoming webhook üzerinden bildirim. İlk kullanım: scheduled reconcile drift alert ([[syntheses/flow-drift-reconciliation]]).

## Implementasyon

`SlackNotifier` (`com.sedcore.common.notification`):

- **HttpClient**: JDK 11+ standart `java.net.http.HttpClient` — ekstra dependency yok
- **Config**: `slack.webhook.url` property (default boş → no-op)
- **Timeout**: connect 5s, request 10s
- **Fail-safe**: exception loglanır, çağıranı bloke etmez

## API

```java
@Component
public class SlackNotifier {
    public boolean isConfigured();
    public void notify(String text);
}
```

## Kullanım

```java
@Autowired SlackNotifier slackNotifier;

slackNotifier.notify(":warning: Drift detected — count=5");
```

İçerik basit JSON: `{"text":"<escaped>"}`. Rich block/attachment desteği yok.

## Config

`application.properties`:
```properties
# Dev/local — boş bırak, no-op
slack.webhook.url=

# Prod
slack.webhook.url=https://hooks.slack.com/services/XXX/YYY/ZZZ
```

Webhook URL Slack workspace admin'den alınır.

## Kullanım Noktaları

| Kaynak | Ne zaman |
|---|---|
| `ReconcileScheduledJob` | Nightly sonrası — drift > 0 veya exception varsa |
| (Gelecek) StockLevel critical alarm | Minimum stok eşiği altına düşüldüğünde |
| (Gelecek) Credit limit aşım auto-override | STORE_ADMIN override yapıldığında audit trail |

## Tuzaklar

- **Rate limit**: Slack webhook'u dakikada ~1 mesaj/saniye. Tight loop'ta throttle gerekir
- **Secret management**: Webhook URL prod'da env var'dan geliyor olmalı (`SLACK_WEBHOOK_URL`) — application.properties'te plain text yasak
- **Channel karışıklığı**: Webhook URL tek kanala bağlı — alert türüne göre farklı kanal istiyorsan farklı webhook URL
- **Escape**: JSON string escape dahili; multiline text `\n` olarak serialize edilir

## Genişletme

Birden fazla kanal/alert türü olursa pattern:
- Enum `AlertType` (RECONCILE, STOCK_CRITICAL, SALES_ANOMALY...)
- `@ConfigurationProperties` ile `Map<AlertType, String webhookUrl>`
- `SlackNotifier.notify(AlertType, text)` → uygun webhook seçer

## Sources

- `pos-product-manager/src/main/java/com/sedcore/common/notification/SlackNotifier.java`
- `pos-product-manager/src/main/java/com/sedcore/finance/job/ReconcileScheduledJob.java` (ilk kullanıcı)
- `pos-product-manager/src/main/resources/application.properties` (`slack.webhook.url`)

## Related

- [[syntheses/flow-drift-reconciliation]] (ilk alert kaynağı)
- [[syntheses/integration-prometheus-micrometer]] (alternatif — metrics-based alerting)
