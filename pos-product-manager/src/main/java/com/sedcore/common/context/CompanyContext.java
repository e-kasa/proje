package com.sedcore.common.context;

/**
 * Thread-local company_code tutucu.
 *
 * API Gateway'den gelen X-Company-Code header'ı bu sınıf üzerinden
 * tüm katmanlara (Service, Repository) taşınır.
 *
 * Her isteğin başında set edilir, sonunda clear edilir.
 * (CompanyContextFilter sorumludur)
 */
public final class CompanyContext {

    private static final ThreadLocal<String> HOLDER = new ThreadLocal<>();

    private CompanyContext() {}

    public static void set(String companyCode) {
        HOLDER.set(companyCode);
    }

    public static String get() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }

    public static boolean hasCompany() {
        String code = HOLDER.get();
        return code != null && !code.isBlank();
    }
}
