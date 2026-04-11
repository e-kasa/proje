package com.sedcore.report.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.report.model.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Random;

/**
 * E-ticaret istatistik servisi.
 *
 * Tüm metodlar CompanyHibernateFilterActivator tarafından sarılır:
 * session.enableFilter("filterCompany").setParameter("cpCode", companyCode)
 * Bu sayede her firma sadece kendi verisini görür.
 *
 * NOT: Şu an demo/seed verisiyle çalışmaktadır.
 * Repository katmanı entegre edildiğinde gerçek sorguları buraya ekleyin.
 * Her metod için TODO yorumları bırakılmıştır.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StatsService {

    // TODO: İleride bu repository'leri inject et
    // private final SaleRepository saleRepository;
    // private final CustomerRepository customerRepository;
    // private final ProductRepository productRepository;

    /**
     * KPI özet kartları için ana istatistikler.
     * Hibernate filtresi aktif olduğundan sadece bu firmanın verisi döner.
     */
    public StatsOverviewResponse getOverview() {
        String company = CompanyContext.get();
        log.info("Stats overview isteniyor, company: {}", company);

        // TODO: Gerçek implementasyon:
        // BigDecimal totalRevenue = saleRepository.sumRevenue();
        // BigDecimal monthRevenue = saleRepository.sumRevenueByMonth(YearMonth.now());
        // BigDecimal lastMonthRevenue = saleRepository.sumRevenueByMonth(YearMonth.now().minusMonths(1));
        // Long totalOrders = saleRepository.count();
        // ...

        // Şimdilik seed data (firma bazında farklı değerler üret)
        Random r = seededRandom(company);

        BigDecimal base = BigDecimal.valueOf(50_000 + r.nextInt(450_000));
        BigDecimal monthRev = base.multiply(BigDecimal.valueOf(0.08 + r.nextDouble() * 0.05))
                .setScale(2, RoundingMode.HALF_UP);
        BigDecimal todayRev = monthRev.multiply(BigDecimal.valueOf(0.03 + r.nextDouble() * 0.02))
                .setScale(2, RoundingMode.HALF_UP);

        long totalOrders = 500L + r.nextInt(9500);
        long monthOrders = totalOrders / 12 + r.nextInt(50);

        return StatsOverviewResponse.builder()
                .totalRevenue(base)
                .todayRevenue(todayRev)
                .monthRevenue(monthRev)
                .revenueChangePercent(roundDouble(r.nextDouble() * 40 - 10))  // -10 ile +30 arası
                .totalOrders(totalOrders)
                .pendingOrders((long)(totalOrders * 0.12))
                .completedOrders((long)(totalOrders * 0.76))
                .cancelledOrders((long)(totalOrders * 0.12))
                .monthOrders(monthOrders)
                .ordersChangePercent(roundDouble(r.nextDouble() * 30 - 5))
                .totalCustomers(1000L + r.nextInt(9000))
                .newCustomers(50L + r.nextInt(200))
                .customersChangePercent(roundDouble(r.nextDouble() * 25))
                .activeProducts(100L + r.nextInt(900))
                .outOfStockProducts(5L + r.nextInt(45))
                .averageOrderValue(base.divide(BigDecimal.valueOf(totalOrders), 2, RoundingMode.HALF_UP))
                .conversionRate(roundDouble(1.5 + r.nextDouble() * 3.5))
                .build();
    }

    /**
     * Gelir trendi grafiği.
     *
     * @param period "daily" | "weekly" | "monthly" | "yearly"
     */
    public RevenueDataResponse getRevenueTrend(String period) {
        String company = CompanyContext.get();
        log.info("Revenue trend isteniyor, period: {}, company: {}", period, company);

        // TODO: Gerçek implementasyon:
        // return switch (period) {
        //     case "monthly" -> buildMonthly(saleRepository.monthlyRevenue(Year.now()));
        //     case "weekly"  -> buildWeekly(saleRepository.weeklyRevenue());
        //     default        -> buildDaily(saleRepository.dailyRevenue());
        // };

        Random r = seededRandom(company + period);

        return switch (period) {
            case "daily"   -> buildDailySeed(r);
            case "weekly"  -> buildWeeklySeed(r);
            case "yearly"  -> buildYearlySeed(r);
            default        -> buildMonthlySeed(r);
        };
    }

    /**
     * En çok satan ürünler listesi.
     *
     * @param limit Kaç ürün (max 20)
     */
    public List<TopProductResponse> getTopProducts(int limit) {
        String company = CompanyContext.get();
        log.info("Top products isteniyor, limit: {}, company: {}", limit, company);

        // TODO: Gerçek implementasyon:
        // return saleRepository.findTopSellingProducts(
        //     PageRequest.of(0, Math.min(limit, 20))
        // ).stream().map(this::toTopProductResponse).toList();

        Random r = seededRandom(company);
        String[] names  = {"Laptop Pro X1","Kablosuz Kulaklık","Akıllı Saat","Mekanik Klavye","Oyuncu Mouse","4K Monitör","USB-C Hub","SSD 1TB","Webcam HD","Tablet 10\""};
        String[] cats   = {"Bilgisayar","Ses","Aksesuar","Çevre Birimi","Depolama","Görüntüleme","Bağlantı","Tablet"};
        String[] trends = {"up","up","up","down","stable"};

        List<TopProductResponse> list = new ArrayList<>();
        int count = Math.min(limit, names.length);
        long baseUnits = 500 + r.nextInt(1500);

        for (int i = 0; i < count; i++) {
            long units = baseUnits - (i * 40L) - r.nextInt(60);
            BigDecimal price  = BigDecimal.valueOf(200 + r.nextInt(1800));
            BigDecimal rev    = price.multiply(BigDecimal.valueOf(units)).setScale(2, RoundingMode.HALF_UP);

            list.add(TopProductResponse.builder()
                    .productId("PRD-" + (1000 + i))
                    .productName(names[i % names.length])
                    .category(cats[i % cats.length])
                    .imageUrl("/assets/img/products/product" + (i + 1) + ".jpg")
                    .unitsSold(units)
                    .revenue(rev)
                    .revenueShare(roundDouble(((count - i) * 100.0) / (count * (count + 1) / 2)))
                    .stockQuantity(r.nextInt(200))
                    .trend(trends[r.nextInt(trends.length)])
                    .build());
        }
        return list;
    }

    /**
     * Sipariş durumu dağılımı — donut chart için.
     */
    public OrderStatusDistribution getOrderStatusDistribution() {
        String company = CompanyContext.get();
        Random r = seededRandom(company + "status");

        long total = 1000 + r.nextInt(4000);
        long completed = (long)(total * (0.65 + r.nextDouble() * 0.15));
        long pending   = (long)(total * (0.10 + r.nextDouble() * 0.08));
        long shipped   = (long)(total * (0.08 + r.nextDouble() * 0.06));
        long cancelled = total - completed - pending - shipped;

        List<String> labels  = List.of("Tamamlandı", "Bekliyor", "Kargoda", "İptal");
        List<Long>   counts  = List.of(completed, pending, shipped, cancelled);
        List<Double> percents = counts.stream()
                .map(c -> roundDouble(c * 100.0 / total))
                .toList();

        return OrderStatusDistribution.builder()
                .labels(labels)
                .counts(counts)
                .percents(percents)
                .build();
    }

    // ── Seed data builder'ları ──────────────────────────────────────────────

    private RevenueDataResponse buildMonthlySeed(Random r) {
        Locale tr = new Locale("tr", "TR");
        List<String>     labels   = new ArrayList<>();
        List<BigDecimal> revenue  = new ArrayList<>();
        List<BigDecimal> expenses = new ArrayList<>();
        List<Long>       orders   = new ArrayList<>();

        LocalDate now = LocalDate.now();
        for (int i = 11; i >= 0; i--) {
            LocalDate m = now.minusMonths(i);
            labels.add(m.getMonth().getDisplayName(TextStyle.SHORT, tr));
            BigDecimal rev = BigDecimal.valueOf(20_000 + r.nextInt(80_000));
            revenue.add(rev);
            expenses.add(rev.multiply(BigDecimal.valueOf(0.4 + r.nextDouble() * 0.25)).setScale(2, RoundingMode.HALF_UP));
            orders.add(100L + r.nextInt(500));
        }
        return RevenueDataResponse.builder().period("monthly").labels(labels).revenue(revenue).expenses(expenses).orders(orders).build();
    }

    private RevenueDataResponse buildDailySeed(Random r) {
        List<String> labels = new ArrayList<>();
        List<BigDecimal> revenue = new ArrayList<>();
        List<BigDecimal> expenses = new ArrayList<>();
        List<Long> orders = new ArrayList<>();
        LocalDate now = LocalDate.now();
        for (int i = 29; i >= 0; i--) {
            labels.add(now.minusDays(i).getDayOfMonth() + "/" + now.minusDays(i).getMonthValue());
            BigDecimal rev = BigDecimal.valueOf(1_000 + r.nextInt(8_000));
            revenue.add(rev);
            expenses.add(rev.multiply(BigDecimal.valueOf(0.35 + r.nextDouble() * 0.3)).setScale(2, RoundingMode.HALF_UP));
            orders.add(10L + r.nextInt(80));
        }
        return RevenueDataResponse.builder().period("daily").labels(labels).revenue(revenue).expenses(expenses).orders(orders).build();
    }

    private RevenueDataResponse buildWeeklySeed(Random r) {
        List<String> labels = new ArrayList<>();
        List<BigDecimal> revenue = new ArrayList<>();
        List<BigDecimal> expenses = new ArrayList<>();
        List<Long> orders = new ArrayList<>();
        for (int i = 12; i >= 0; i--) {
            labels.add("Hafta " + (53 - i));
            BigDecimal rev = BigDecimal.valueOf(5_000 + r.nextInt(25_000));
            revenue.add(rev);
            expenses.add(rev.multiply(BigDecimal.valueOf(0.38 + r.nextDouble() * 0.22)).setScale(2, RoundingMode.HALF_UP));
            orders.add(30L + r.nextInt(200));
        }
        return RevenueDataResponse.builder().period("weekly").labels(labels).revenue(revenue).expenses(expenses).orders(orders).build();
    }

    private RevenueDataResponse buildYearlySeed(Random r) {
        List<String> labels = new ArrayList<>();
        List<BigDecimal> revenue = new ArrayList<>();
        List<BigDecimal> expenses = new ArrayList<>();
        List<Long> orders = new ArrayList<>();
        int year = LocalDate.now().getYear();
        for (int i = 4; i >= 0; i--) {
            labels.add(String.valueOf(year - i));
            BigDecimal rev = BigDecimal.valueOf(200_000 + r.nextInt(800_000));
            revenue.add(rev);
            expenses.add(rev.multiply(BigDecimal.valueOf(0.4 + r.nextDouble() * 0.2)).setScale(2, RoundingMode.HALF_UP));
            orders.add(1000L + r.nextInt(5000));
        }
        return RevenueDataResponse.builder().period("yearly").labels(labels).revenue(revenue).expenses(expenses).orders(orders).build();
    }

    /** Firma adından deterministik seed üret — her firma farklı ama tutarlı veri görür */
    private Random seededRandom(String key) {
        return new Random(key == null ? 42L : key.hashCode());
    }

    private Double roundDouble(double val) {
        return Math.round(val * 100.0) / 100.0;
    }
}
