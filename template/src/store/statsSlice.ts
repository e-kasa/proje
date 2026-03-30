import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";
import { statsService } from "../services/statsService";
import type {
  StatsOverview,
  RevenueData,
  TopProduct,
  OrderStatusDistribution,
  RevenuePeriod,
} from "../services/statsService";

// ── State ────────────────────────────────────────────────────────────────────

interface StatsState {
  overview: StatsOverview | null;
  revenue: RevenueData | null;
  topProducts: TopProduct[];
  orderStatus: OrderStatusDistribution | null;

  revenuePeriod: RevenuePeriod;

  loadingOverview: boolean;
  loadingRevenue: boolean;
  loadingTopProducts: boolean;
  loadingOrderStatus: boolean;

  errorOverview: string | null;
  errorRevenue: string | null;
  errorTopProducts: string | null;
  errorOrderStatus: string | null;
}

const initialState: StatsState = {
  overview: null,
  revenue: null,
  topProducts: [],
  orderStatus: null,

  revenuePeriod: "monthly",

  loadingOverview: false,
  loadingRevenue: false,
  loadingTopProducts: false,
  loadingOrderStatus: false,

  errorOverview: null,
  errorRevenue: null,
  errorTopProducts: null,
  errorOrderStatus: null,
};

// ── Async Thunks ─────────────────────────────────────────────────────────────

export const fetchOverview = createAsyncThunk<StatsOverview, void>(
  "stats/fetchOverview",
  async (_, { rejectWithValue }) => {
    try {
      return await statsService.getOverview();
    } catch (err: any) {
      return rejectWithValue(err?.response?.data?.message ?? "Bağlantı hatası");
    }
  }
);

export const fetchRevenueTrend = createAsyncThunk<RevenueData, RevenuePeriod>(
  "stats/fetchRevenueTrend",
  async (period, { rejectWithValue }) => {
    try {
      return await statsService.getRevenueTrend(period);
    } catch (err: any) {
      return rejectWithValue(err?.response?.data?.message ?? "Bağlantı hatası");
    }
  }
);

export const fetchTopProducts = createAsyncThunk<TopProduct[], number | undefined>(
  "stats/fetchTopProducts",
  async (limit = 10, { rejectWithValue }) => {
    try {
      return await statsService.getTopProducts(limit);
    } catch (err: any) {
      return rejectWithValue(err?.response?.data?.message ?? "Bağlantı hatası");
    }
  }
);

export const fetchOrderStatus = createAsyncThunk<OrderStatusDistribution, void>(
  "stats/fetchOrderStatus",
  async (_, { rejectWithValue }) => {
    try {
      return await statsService.getOrderStatus();
    } catch (err: any) {
      return rejectWithValue(err?.response?.data?.message ?? "Bağlantı hatası");
    }
  }
);

/** Tüm dashboard verilerini tek seferde yükle */
export const fetchAllStats = createAsyncThunk<void, RevenuePeriod | undefined>(
  "stats/fetchAll",
  async (period = "monthly", { dispatch }) => {
    await Promise.all([
      dispatch(fetchOverview()),
      dispatch(fetchRevenueTrend(period)),
      dispatch(fetchTopProducts(10)),
      dispatch(fetchOrderStatus()),
    ]);
  }
);

// ── Slice ────────────────────────────────────────────────────────────────────

const statsSlice = createSlice({
  name: "stats",
  initialState,
  reducers: {
    setRevenuePeriod(state, action: PayloadAction<RevenuePeriod>) {
      state.revenuePeriod = action.payload;
    },
    resetStats(state) {
      Object.assign(state, initialState);
    },
  },
  extraReducers: (builder) => {
    // Overview
    builder
      .addCase(fetchOverview.pending, (state) => {
        state.loadingOverview = true;
        state.errorOverview = null;
      })
      .addCase(fetchOverview.fulfilled, (state, action) => {
        state.loadingOverview = false;
        state.overview = action.payload;
      })
      .addCase(fetchOverview.rejected, (state, action) => {
        state.loadingOverview = false;
        state.errorOverview = action.payload as string;
      });

    // Revenue
    builder
      .addCase(fetchRevenueTrend.pending, (state) => {
        state.loadingRevenue = true;
        state.errorRevenue = null;
      })
      .addCase(fetchRevenueTrend.fulfilled, (state, action) => {
        state.loadingRevenue = false;
        state.revenue = action.payload;
        state.revenuePeriod = action.payload.period as RevenuePeriod;
      })
      .addCase(fetchRevenueTrend.rejected, (state, action) => {
        state.loadingRevenue = false;
        state.errorRevenue = action.payload as string;
      });

    // Top Products
    builder
      .addCase(fetchTopProducts.pending, (state) => {
        state.loadingTopProducts = true;
        state.errorTopProducts = null;
      })
      .addCase(fetchTopProducts.fulfilled, (state, action) => {
        state.loadingTopProducts = false;
        state.topProducts = action.payload;
      })
      .addCase(fetchTopProducts.rejected, (state, action) => {
        state.loadingTopProducts = false;
        state.errorTopProducts = action.payload as string;
      });

    // Order Status
    builder
      .addCase(fetchOrderStatus.pending, (state) => {
        state.loadingOrderStatus = true;
        state.errorOrderStatus = null;
      })
      .addCase(fetchOrderStatus.fulfilled, (state, action) => {
        state.loadingOrderStatus = false;
        state.orderStatus = action.payload;
      })
      .addCase(fetchOrderStatus.rejected, (state, action) => {
        state.loadingOrderStatus = false;
        state.errorOrderStatus = action.payload as string;
      });
  },
});

export const { setRevenuePeriod, resetStats } = statsSlice.actions;
export default statsSlice.reducer;
