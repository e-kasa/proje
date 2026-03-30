import React from "react";
import { BrowserRouter, Route, Routes, Navigate } from "react-router-dom";
import FeatureModule from "./feature-module/feature-module";
import { authRoutes, posPages, unAuthRoutes, storefrontRoutes } from "./routes/path";
import { base_path } from "./environment";
import { useSelector } from "react-redux";
import type {RootState} from "./core/redux/store.tsx";

const AppRouter: React.FC = () => {
    // 🔸 Token'ı Redux store'dan al
    const token = useSelector((state: RootState) => state.auth?.token);


    const RouterContent = React.memo(() => {

        const renderRoutes = (routeList: any[], _isProtected: boolean) =>
            routeList?.map((item) => (
                <Route
                    key={`route-${item?.id}`}
                    path={item?.path}
                    element={
                        _isProtected ? (
                            token ? (
                                item?.element
                            ) : (
                                // Eğer token yoksa login sayfasına yönlendir
                                <Navigate to="/signin" replace />
                            )
                        ) : (
                            item?.element
                        )
                    }
                />
            ));

        return (
            <Routes>
                <Route path="/" element={<FeatureModule />}>
                    {/* Public routes */}
                    {renderRoutes(unAuthRoutes, false)}

                    {/* Storefront routes (herkese açık) */}
                    {renderRoutes(storefrontRoutes, false)}

                    {/* Private routes (token gerek) */}
                    {renderRoutes(authRoutes, true)}
                    {renderRoutes(posPages, true)}

                    {/* Default redirect: her zaman store'a git */}
                    <Route
                        path="/"
                        element={<Navigate to="/store" replace />}
                    />
                </Route>
            </Routes>
        );
    });

    return (
        <BrowserRouter basename={base_path}>
            <RouterContent />
        </BrowserRouter>
    );
};

export default AppRouter;
