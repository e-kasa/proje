import { combineReducers, configureStore } from "@reduxjs/toolkit";
import { getPreloadedState, saveToLocalStorage } from "./localStorage";
import sidebarSlice from "./sidebarSlice";
import commonSlice from "./commonSlice";
import MainReducer from "./reducer";
import themeSettingSlice from "./themeSettingSlice";
import authReducer from "./authSlice.ts";
import cartReducer from "../../store/cartSlice.ts";
import wishlistReducer from "../../store/wishlistSlice.ts";
import statsReducer from "../../store/statsSlice.ts";

const combinedReducer = combineReducers({
  sidebar: sidebarSlice,
  common: commonSlice,
  rootReducer: MainReducer,
  themeSetting: themeSettingSlice,
  auth: authReducer,
  cart: cartReducer,
  wishlist: wishlistReducer,
  stats: statsReducer,
});

const rootReducer = (state: any, action: any) => {
  if (action.type === "login/logout") {
    state = undefined;
  }

  return combinedReducer(state, action);
};

const store = configureStore({
  reducer: rootReducer,
  preloadedState: getPreloadedState(),
});

function onStateChange() {
  saveToLocalStorage(store.getState());
}

store.subscribe(onStateChange);
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export default store;
