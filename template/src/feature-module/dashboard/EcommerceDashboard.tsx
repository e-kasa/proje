/**
 * EcommerceDashboard.tsx
 *
 * Çok kiracılı (multi-tenant) e-ticaret istatistik dashboard'u.
 * Her firma kendi domain'i üzerinden bağlanır; gateway X-Company-Code
 * header'ını otomatik ekler — bu bileşen hiçbir firma kodunu
 * doğrudan bilmek zorunda değildir.
 *
 * Bölümler:
 *  1. KPI Kartları  — Gelir / Sipariş / Müşteri / Dönüşüm Oranı
 *  2. Gelir Trendi  — Area chart (ApexCharts), dönem seçici
 *  3. En Çok Satanlar — Tablo + trend ikonları
 *  4. Sipariş Durumu — Donut chart (ApexCharts)
 */

import { useEffect, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import CountUp from "react-countup";
import Chart from "react-apexcharts";
import { ApexOptions } from "apexcharts";

import { AppDispatch, RootState } from "../../core/redux/store";
import {
  fetchAllStats,
  fetchRevenueTrend,
  setRevenuePeriod,
} from "../../store/statsSlice";
import { RevenuePeriod } from "../../services/statsService";

// ── Yardımcı: para formatı ────────────────────────────────────────────────────

function formatCurrency(value: number): string {
  if (value >= 1_000_000) return `₺${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `₺${(value / 1_000).toFixed(1)}K`;
  return `₺${value.toFixed(2)}`;
}

// ── KPI Kart bileşeni ─────────────────────────────────────────────────────────

interface KpiCardProps {
  title: string;
  value: number;
  prefix?: string;
  suffix?: string;
  decimals?: number;
  changePercent?: number;
  icon: string;
  color: string;
  loading: boolean;
}

const KpiCard = ({
  title,
  value,
  prefix = "",
  suffix = "",
  decimals = 0,
  changePercent,
  icon,
  color,
  loading,
}: KpiCardProps) => {
  const isPositive = (changePercent ?? 0) >= 0;

  return (
    <div className="col-xl-3 col-sm-6 col-12 d-flex">
      <div className="dash-count w-100">
        <div className="dash-counts">
          <h4>
            {loading ? (
              <span className="placeholder col-6 bg-secondary rounded" />
            ) : (
              <CountUp
                start={0}
                end={value}
                duration={1.6}
                decimals={decimals}
                prefix={prefix}
                suffix={suffix}
                separator=","
              />
            )}
          </h4>
          <h5>{title}</h5>
          {changePercent !== undefined && !loading && (
            <span
              className={`badge ${isPositive ? "badge-success" : "badge-danger"} ms-1`}
              style={{ fontSize: "0.72rem" }}
            >
              <i
                className={`ti ti-trending-${isPositive ? "up" : "down"} me-1`}
              />
              {Math.abs(changePercent).toFixed(1)}%
            </span>
          )}
        </div>
        <div className="dash-imgs">
          <i className={`${icon}`} style={{ color }} />
        </div>
      </div>
    </div>
  );
};

// ── Dönem seçici düğme grubu ──────────────────────────────────────────────────

const PERIODS: { key: RevenuePeriod; label: string }[] = [
  { key: "daily", label: "Günlük" },
  { key: "weekly", label: "Haftalık" },
  { key: "monthly", label: "Aylık" },
  { key: "yearly", label: "Yıllık" },
];

// ── Ana bileşen ───────────────────────────────────────────────────────────────

const EcommerceDashboard = () => {
  const dispatch = useDispatch<AppDispatch>();

  const {
    overview,
    revenue,
    topProducts,
    orderStatus,
    revenuePeriod,
    loadingOverview,
    loadingRevenue,
    loadingTopProducts,
    loadingOrderStatus,
  } = useSelector((state: RootState) => state.stats);

  // İlk yükleme
  useEffect(() => {
    dispatch(fetchAllStats("monthly"));
  }, [dispatch]);

  // Dönem değişimi
  const handlePeriodChange = useCallback(
    (period: RevenuePeriod) => {
      dispatch(setRevenuePeriod(period));
      dispatch(fetchRevenueTrend(period));
    },
    [dispatch]
  );

  // ── Gelir trendi grafik ayarları ──────────────────────────────────────────

  const revenueChartOptions: ApexOptions = {
    chart: {
      type: "area",
      height: 320,
      toolbar: { show: false },
      zoom: { enabled: false },
      animations: { enabled: true, speed: 600 },
    },
    colors: ["#5C67F2", "#28C76F", "#EA5455"],
    fill: {
      type: "gradient",
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.45,
        opacityTo: 0.05,
        stops: [0, 90, 100],
      },
    },
    stroke: { curve: "smooth", width: 2 },
    dataLabels: { enabled: false },
    xaxis: {
      categories: revenue?.labels ?? [],
      axisBorder: { show: false },
      axisTicks: { show: false },
      labels: { style: { colors: "#9e9e9e", fontSize: "12px" } },
    },
    yaxis: {
      labels: {
        formatter: (val: number) => formatCurrency(val),
        style: { colors: "#9e9e9e", fontSize: "12px" },
      },
    },
    grid: { borderColor: "#f1f1f1", strokeDashArray: 4 },
    tooltip: {
      y: { formatter: (val: number) => formatCurrency(val) },
    },
    legend: {
      position: "top",
      horizontalAlign: "right",
      markers: { size: 8 },
    },
  };

  const revenueChartSeries = [
    { name: "Gelir", data: revenue?.revenue ?? [] },
    { name: "Gider", data: revenue?.expenses ?? [] },
    { name: "Sipariş (adet)", data: revenue?.orders ?? [] },
  ];

  // ── Donut chart ayarları ─────────────────────────────────────────────────

  const donutOptions: ApexOptions = {
    chart: { type: "donut", height: 280, animations: { speed: 600 } },
    labels: orderStatus?.labels ?? [],
    colors: ["#28C76F", "#FF9F43", "#5C67F2", "#EA5455"],
    dataLabels: { enabled: false },
    legend: {
      position: "bottom",
      markers: { size: 8 },
      fontSize: "13px",
    },
    plotOptions: {
      pie: {
        donut: {
          size: "68%",
          labels: {
            show: true,
            total: {
              show: true,
              label: "Toplam",
              fontSize: "14px",
              color: "#9e9e9e",
              formatter: (w) =>
                w.globals.seriesTotals
                  .reduce((a: number, b: number) => a + b, 0)
                  .toLocaleString("tr-TR"),
            },
          },
        },
      },
    },
    tooltip: {
      y: {
        formatter: (val: number, { seriesIndex }: { seriesIndex: number }) => {
          const pct = orderStatus?.percents?.[seriesIndex] ?? 0;
          return `${val.toLocaleString("tr-TR")} sipariş (${pct.toFixed(1)}%)`;
        },
      },
    },
  };

  const donutSeries = orderStatus?.counts ?? [];

  // ── Trend ikonu yardımcı ─────────────────────────────────────────────────

  const TrendIcon = ({ trend }: { trend: string }) => {
    if (trend === "up")
      return <i className="ti ti-trending-up text-success ms-1" />;
    if (trend === "down")
      return <i className="ti ti-trending-down text-danger ms-1" />;
    return <i className="ti ti-minus text-warning ms-1" />;
  };

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="page-wrapper">
      <div className="content">
        {/* Sayfa başlığı */}
        <div className="page-header">
          <div className="page-title">
            <h4>E-Ticaret Dashboard</h4>
            <h6 className="text-muted">Satış ve performans istatistikleri</h6>
          </div>
          <div className="page-btn">
            <button
              className="btn btn-outline-secondary btn-sm"
              onClick={() => dispatch(fetchAllStats(revenuePeriod))}
            >
              <i className="ti ti-refresh me-1" />
              Yenile
            </button>
          </div>
        </div>

        {/* ── KPI Kartları ── */}
        <div className="row">
          <KpiCard
            title="Toplam Gelir"
            value={overview?.totalRevenue ?? 0}
            prefix="₺"
            decimals={2}
            changePercent={overview?.revenueChangePercent}
            icon="ti ti-currency-lira fs-2"
            color="#5C67F2"
            loading={loadingOverview}
          />
          <KpiCard
            title="Toplam Sipariş"
            value={overview?.totalOrders ?? 0}
            changePercent={overview?.ordersChangePercent}
            icon="ti ti-shopping-cart fs-2"
            color="#28C76F"
            loading={loadingOverview}
          />
          <KpiCard
            title="Toplam Müşteri"
            value={overview?.totalCustomers ?? 0}
            changePercent={overview?.customersChangePercent}
            icon="ti ti-users fs-2"
            color="#FF9F43"
            loading={loadingOverview}
          />
          <KpiCard
            title="Dönüşüm Oranı"
            value={overview?.conversionRate ?? 0}
            suffix="%"
            decimals={1}
            icon="ti ti-chart-pie fs-2"
            color="#EA5455"
            loading={loadingOverview}
          />
        </div>

        {/* ── 2. satır KPI ── */}
        <div className="row">
          <div className="col-xl-3 col-sm-6 col-12 d-flex">
            <div className="dash-count das1 w-100">
              <div className="dash-counts">
                <h4>
                  {loadingOverview ? (
                    <span className="placeholder col-5 bg-light rounded" />
                  ) : (
                    <CountUp
                      end={overview?.todayRevenue ?? 0}
                      duration={1.4}
                      decimals={2}
                      prefix="₺"
                      separator=","
                    />
                  )}
                </h4>
                <h5>Bugünkü Gelir</h5>
              </div>
              <div className="dash-imgs">
                <i className="ti ti-calendar-dollar fs-2" style={{ color: "#5C67F2" }} />
              </div>
            </div>
          </div>
          <div className="col-xl-3 col-sm-6 col-12 d-flex">
            <div className="dash-count das2 w-100">
              <div className="dash-counts">
                <h4>
                  {loadingOverview ? (
                    <span className="placeholder col-5 bg-light rounded" />
                  ) : (
                    <CountUp
                      end={overview?.monthRevenue ?? 0}
                      duration={1.4}
                      decimals={2}
                      prefix="₺"
                      separator=","
                    />
                  )}
                </h4>
                <h5>Bu Ay Gelir</h5>
              </div>
              <div className="dash-imgs">
                <i className="ti ti-calendar-stats fs-2" style={{ color: "#28C76F" }} />
              </div>
            </div>
          </div>
          <div className="col-xl-3 col-sm-6 col-12 d-flex">
            <div className="dash-count das3 w-100">
              <div className="dash-counts">
                <h4>
                  {loadingOverview ? (
                    <span className="placeholder col-5 bg-light rounded" />
                  ) : (
                    <CountUp
                      end={overview?.pendingOrders ?? 0}
                      duration={1.4}
                      separator=","
                    />
                  )}
                </h4>
                <h5>Bekleyen Sipariş</h5>
              </div>
              <div className="dash-imgs">
                <i className="ti ti-clock fs-2" style={{ color: "#FF9F43" }} />
              </div>
            </div>
          </div>
          <div className="col-xl-3 col-sm-6 col-12 d-flex">
            <div className="dash-count das4 w-100">
              <div className="dash-counts">
                <h4>
                  {loadingOverview ? (
                    <span className="placeholder col-5 bg-light rounded" />
                  ) : (
                    <CountUp
                      end={overview?.averageOrderValue ?? 0}
                      duration={1.4}
                      decimals={2}
                      prefix="₺"
                      separator=","
                    />
                  )}
                </h4>
                <h5>Ortalama Sipariş Değeri</h5>
              </div>
              <div className="dash-imgs">
                <i className="ti ti-receipt fs-2" style={{ color: "#EA5455" }} />
              </div>
            </div>
          </div>
        </div>

        {/* ── Grafik satırı ── */}
        <div className="row">
          {/* Gelir trendi */}
          <div className="col-xl-8 col-sm-12 col-12 d-flex">
            <div className="card flex-fill">
              <div className="card-header d-flex align-items-center justify-content-between flex-wrap row-gap-3">
                <h5 className="card-title mb-0">Gelir Trendi</h5>
                <div className="btn-group" role="group">
                  {PERIODS.map(({ key, label }) => (
                    <button
                      key={key}
                      type="button"
                      className={`btn btn-sm ${
                        revenuePeriod === key
                          ? "btn-primary"
                          : "btn-outline-secondary"
                      }`}
                      onClick={() => handlePeriodChange(key)}
                      disabled={loadingRevenue}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>
              <div className="card-body">
                {loadingRevenue ? (
                  <div
                    className="d-flex align-items-center justify-content-center"
                    style={{ height: 320 }}
                  >
                    <div className="spinner-border text-primary" role="status">
                      <span className="visually-hidden">Yükleniyor…</span>
                    </div>
                  </div>
                ) : (
                  <Chart
                    options={revenueChartOptions}
                    series={revenueChartSeries}
                    type="area"
                    height={320}
                  />
                )}
              </div>
            </div>
          </div>

          {/* Sipariş durumu donut */}
          <div className="col-xl-4 col-sm-12 col-12 d-flex">
            <div className="card flex-fill">
              <div className="card-header">
                <h5 className="card-title mb-0">Sipariş Durumları</h5>
              </div>
              <div className="card-body d-flex align-items-center justify-content-center">
                {loadingOrderStatus ? (
                  <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Yükleniyor…</span>
                  </div>
                ) : donutSeries.length > 0 ? (
                  <Chart
                    options={donutOptions}
                    series={donutSeries as number[]}
                    type="donut"
                    height={280}
                    width="100%"
                  />
                ) : (
                  <p className="text-muted">Veri bulunamadı</p>
                )}
              </div>

              {/* Donut alt özet */}
              {!loadingOrderStatus && orderStatus && (
                <div className="card-footer border-top-0 pt-0">
                  <div className="row text-center g-2">
                    {orderStatus.labels.map((label, i) => (
                      <div key={label} className="col-6">
                        <span className="d-block fw-semibold fs-6">
                          {orderStatus.counts[i]?.toLocaleString("tr-TR")}
                        </span>
                        <span className="text-muted" style={{ fontSize: "0.78rem" }}>
                          {label}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* ── En Çok Satan Ürünler ── */}
        <div className="row">
          <div className="col-12">
            <div className="card">
              <div className="card-header d-flex align-items-center justify-content-between">
                <h5 className="card-title mb-0">En Çok Satan Ürünler</h5>
                <span className="badge bg-primary-transparent text-primary">
                  Top {topProducts.length}
                </span>
              </div>
              <div className="card-body p-0">
                <div className="table-responsive">
                  <table className="table table-hover table-nowrap mb-0">
                    <thead className="table-light">
                      <tr>
                        <th>#</th>
                        <th>Ürün</th>
                        <th>Kategori</th>
                        <th className="text-end">Satış (Adet)</th>
                        <th className="text-end">Gelir</th>
                        <th className="text-end">Gelir Payı</th>
                        <th className="text-end">Stok</th>
                        <th className="text-center">Trend</th>
                      </tr>
                    </thead>
                    <tbody>
                      {loadingTopProducts
                        ? Array.from({ length: 6 }).map((_, i) => (
                            <tr key={i}>
                              {Array.from({ length: 8 }).map((__, j) => (
                                <td key={j}>
                                  <span className="placeholder col-8 bg-light rounded d-block" />
                                </td>
                              ))}
                            </tr>
                          ))
                        : topProducts.map((product, idx) => (
                            <tr key={product.productId}>
                              <td>
                                <span className="text-muted">{idx + 1}</span>
                              </td>
                              <td>
                                <div className="d-flex align-items-center gap-2">
                                  <img
                                    src={product.imageUrl}
                                    alt={product.productName}
                                    width={36}
                                    height={36}
                                    className="rounded object-fit-cover"
                                    onError={(e) => {
                                      (e.target as HTMLImageElement).src =
                                        "/assets/img/products/placeholder.jpg";
                                    }}
                                  />
                                  <div>
                                    <span className="fw-medium">
                                      {product.productName}
                                    </span>
                                    <br />
                                    <span
                                      className="text-muted"
                                      style={{ fontSize: "0.76rem" }}
                                    >
                                      {product.productId}
                                    </span>
                                  </div>
                                </div>
                              </td>
                              <td>
                                <span className="badge bg-light text-dark">
                                  {product.category}
                                </span>
                              </td>
                              <td className="text-end fw-medium">
                                {product.unitsSold.toLocaleString("tr-TR")}
                              </td>
                              <td className="text-end fw-medium text-success">
                                {formatCurrency(product.revenue)}
                              </td>
                              <td className="text-end">
                                <div
                                  className="d-flex align-items-center justify-content-end gap-2"
                                >
                                  <div
                                    className="progress flex-grow-1"
                                    style={{ height: 6, maxWidth: 80 }}
                                  >
                                    <div
                                      className="progress-bar bg-primary"
                                      style={{
                                        width: `${product.revenueShare}%`,
                                      }}
                                    />
                                  </div>
                                  <span style={{ fontSize: "0.82rem" }}>
                                    {product.revenueShare.toFixed(1)}%
                                  </span>
                                </div>
                              </td>
                              <td className="text-end">
                                <span
                                  className={
                                    product.stockQuantity === 0
                                      ? "badge bg-danger-transparent text-danger"
                                      : product.stockQuantity < 10
                                      ? "badge bg-warning-transparent text-warning"
                                      : "text-muted"
                                  }
                                >
                                  {product.stockQuantity === 0
                                    ? "Tükendi"
                                    : product.stockQuantity}
                                </span>
                              </td>
                              <td className="text-center">
                                <TrendIcon trend={product.trend} />
                              </td>
                            </tr>
                          ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ── Alt satır: Mini KPI özeti ── */}
        {overview && !loadingOverview && (
          <div className="row">
            <div className="col-xl-4 col-sm-6 col-12 d-flex">
              <div className="card flex-fill">
                <div className="card-body">
                  <h6 className="text-muted mb-3">Sipariş Özeti</h6>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Tamamlanan</span>
                    <span className="fw-semibold text-success">
                      {overview.completedOrders.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Bekleyen</span>
                    <span className="fw-semibold text-warning">
                      {overview.pendingOrders.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span>İptal</span>
                    <span className="fw-semibold text-danger">
                      {overview.cancelledOrders.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span>Bu Ay</span>
                    <span className="fw-semibold text-primary">
                      {overview.monthOrders.toLocaleString("tr-TR")}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div className="col-xl-4 col-sm-6 col-12 d-flex">
              <div className="card flex-fill">
                <div className="card-body">
                  <h6 className="text-muted mb-3">Müşteri Özeti</h6>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Toplam Müşteri</span>
                    <span className="fw-semibold">
                      {overview.totalCustomers.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Yeni Müşteri</span>
                    <span className="fw-semibold text-success">
                      +{overview.newCustomers.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span>Büyüme</span>
                    <span
                      className={`fw-semibold ${
                        overview.customersChangePercent >= 0
                          ? "text-success"
                          : "text-danger"
                      }`}
                    >
                      {overview.customersChangePercent >= 0 ? "+" : ""}
                      {overview.customersChangePercent.toFixed(1)}%
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div className="col-xl-4 col-sm-12 col-12 d-flex">
              <div className="card flex-fill">
                <div className="card-body">
                  <h6 className="text-muted mb-3">Ürün Özeti</h6>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Aktif Ürün</span>
                    <span className="fw-semibold text-success">
                      {overview.activeProducts.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between mb-2">
                    <span>Stok Tükenen</span>
                    <span className="fw-semibold text-danger">
                      {overview.outOfStockProducts.toLocaleString("tr-TR")}
                    </span>
                  </div>
                  <div className="d-flex justify-content-between">
                    <span>Ort. Sipariş Değeri</span>
                    <span className="fw-semibold text-primary">
                      {formatCurrency(overview.averageOrderValue)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default EcommerceDashboard;
