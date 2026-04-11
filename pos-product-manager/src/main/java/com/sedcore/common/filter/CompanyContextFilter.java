package com.sedcore.common.filter;

import com.sedcore.common.context.CompanyContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * API Gateway'den gelen X-Company-Code header'ını okur
 * ve thread-local CompanyContext'e yazar.
 *
 * Çalışma sırası: JwtXUserInfoFilter'dan ÖNCE (Order = 1).
 * Her isteğin sonunda CompanyContext.clear() ile temizlenir.
 *
 * Public endpoint'lerde (X-User-Info olmasa da) bu filter çalışır
 * çünkü company_code public sorgular için de gereklidir.
 */
@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
public class CompanyContextFilter extends OncePerRequestFilter {

    private static final String HEADER_COMPANY_CODE = "X-Company-Code";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String companyCode = request.getHeader(HEADER_COMPANY_CODE);

            if (companyCode != null && !companyCode.isBlank()) {
                CompanyContext.set(companyCode.trim());
                log.debug("CompanyContext set: {} | path: {}",
                        companyCode, request.getRequestURI());
            } else {
                log.debug("X-Company-Code header bulunamadı: {}", request.getRequestURI());
            }

            filterChain.doFilter(request, response);

        } finally {
            // Thread-local'i her koşulda temizle (thread pool leak önlemi)
            CompanyContext.clear();
        }
    }
}
