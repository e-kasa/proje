import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

interface AuthState {
  token: string | null;
  user: any | null;
  companyCode: string | null;
}

const initialState: AuthState = {
  token: localStorage.getItem("token") || null,
  user: null,
  companyCode: localStorage.getItem("companyCode") || null,
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setCredentials: (
      state,
      action: PayloadAction<{ accessToken: string; user?: any; companyCode?: string }>
    ) => {
      state.token = action.payload.accessToken;
      state.user = action.payload.user ?? null;
      if (action.payload.companyCode) {
        state.companyCode = action.payload.companyCode;
        localStorage.setItem("companyCode", action.payload.companyCode);
      }
      localStorage.setItem("token", action.payload.accessToken);
    },
    logout: (state) => {
      state.token = null;
      state.user = null;
      state.companyCode = null;
      localStorage.removeItem("token");
      localStorage.removeItem("companyCode");
    },
  },
});

export const { setCredentials, logout } = authSlice.actions;
export default authSlice.reducer;
