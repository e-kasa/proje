import axios from "axios";

/**
 * İstatistik API servisi.
 *
 * Tüm istekler API Gateway üzerinden geçer.
 * - React (web): Gateway, Origin header'ından company_code'u çözer.
 * - Flutter/admin: JWT token içindeki company_code kullanılır.
 *
 * Axios instance'ı merkezi token yönetimi yapar (axiosClient/index.ts'deki gibi).
 */

const BASE = (import.meta as any).env?.VITE_API_URL ?? "http://localhost:8080";
const STATS_URL = `${BASE}/product/api/v1/stats`;

function authHeader() {
  const token = localStorage.getItem("token");
  return token ? { Authorization: `Bearer ${token}` } : {};
}

// ── Tipler ────────────────────────────────────────────────────────────────────

export interface StatsOverview {
  totalRevenue: number;
  todayRevenue: number;
  monthRevenue: number;
  revenueChangePercent: number;
  totalOrders: number;
  pendingOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  monthOrders: number;
  ordersChangePercent: number;
  totalCustomers: number;
  newCustomers: number;
  customersChangePercent: number;
  activeProducts: number;
  outOfStockProducts: number;
  averageOrderValue: number;
  conversionRate: number;
}

export interface RevenueData {
  period: string;
  labels: string[];
  revenue: number[];
  orders: number[];
  expenses: number[];
}

export interface TopProduct {
  productId: string;
  productName: string;
  category: string;
  imageUrl: string;
  unitsSold: number;
  revenue: number;
  revenueShare: number;
  stockQuantity: number;
  trend: "up" | "down" | "stable";
}

export interface OrderStatusDistribution {
  labels: string[];
  counts: number[];
  percents: number[];
}

export type RevenuePeriod = "daily" | "weekly" | "monthly" | "yearly";

// ── API Çağrıları ─────────────────────────────────────────────────────────────

export const statsService = {
  /** KPI özet kartları */
  getOverview: async (): Promise<StatsOverview> => {
    const { data } = await axios.get(`${STATS_URL}/overview`, {
      headers: authHeader(),
    });
    return data.data;
  },

  /** Gelir ve sipariş trendi */
  getRevenueTrend: async (period: RevenuePeriod = "monthly"): Promise<RevenueData> => {
    const { data } = await axios.get(`${STATS_URL}/revenue`, {
      params: { period },
      headers: authHeader(),
    });
    return data.data;
  },

  /** En çok satan ürünler */
  getTopProducts: async (limit = 10): Promise<TopProduct[]> => {
    const { data } = await axios.get(`${STATS_URL}/top-products`, {
      params: { limit },
      headers: authHeader(),
    });
    return data.data;
  },

  /** Sipariş durumu dağılımı */
  getOrderStatus: async (): Promise<OrderStatusDistribution> => {
    const { data } = await axios.get(`${STATS_URL}/order-status`, {
      headers: authHeader(),
    });
    return data.data;
  },
};
