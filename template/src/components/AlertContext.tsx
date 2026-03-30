// src/components/AlertContext.tsx
import React, { createContext, useContext, useState, type ReactNode } from "react";
import Alert from "./Alert";

interface AlertOptions {
    type?: "success" | "danger" | "warning" | "info";
    message: string;
    autoClose?: number;
}

interface AlertContextType {
    showAlert: (options: AlertOptions) => void;
    hideAlert: () => void;
}

const AlertContext = createContext<AlertContextType | undefined>(undefined);

export const useAlert = () => {
    const context = useContext(AlertContext);
    if (!context) throw new Error("useAlert must be used within AlertProvider");
    return context;
};

export const AlertProvider: React.FC<{ children: ReactNode }> = ({
                                                                     children,
                                                                 }) => {
    const [alerts, setAlerts] = useState<(AlertOptions & { id: number })[]>([]);
    const [nextId, setNextId] = useState(0);

    const showAlert = (options: AlertOptions) => {
        const id = nextId;
        setNextId(nextId + 1);

        setAlerts((prev) => [
            ...prev,
            {
                ...options,
                id,
                autoClose: options.autoClose ?? 3000,
            },
        ]);

        // Auto remove after autoClose time
        if (options.autoClose !== 0) {
            setTimeout(() => {
                hideAlert(id);
            }, options.autoClose ?? 3000);
        }
    };

    const hideAlert = (id?: number) => {
        if (id !== undefined) {
            setAlerts((prev) => prev.filter((alert) => alert.id !== id));
        } else {
            setAlerts([]);
        }
    };

    return (
        <AlertContext.Provider value={{ showAlert, hideAlert }}>
            {children}

            {/* Render Multiple Alerts Stacked */}
            <div
                className="toast-container position-fixed top-0 end-0 p-3"
                style={{ zIndex: 9999 }}
            >
                {alerts.map((alert, index) => (
                    <div
                        key={alert.id}
                        style={{
                            marginBottom: index < alerts.length - 1 ? "10px" : "0",
                        }}
                    >
                        <Alert
                            type={alert.type}
                            message={alert.message}
                            autoClose={alert.autoClose}
                            onClose={() => hideAlert(alert.id)}
                        />
                    </div>
                ))}
            </div>
        </AlertContext.Provider>
    );
};