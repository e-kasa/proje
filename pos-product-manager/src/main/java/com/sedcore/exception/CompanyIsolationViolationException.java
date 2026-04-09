package com.sedcore.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * CompanyIsolationViolationException - Thrown when multi-tenancy isolation is breached
 * Returns HTTP 403 Forbidden
 *
 * This exception indicates a security violation where:
 * - User tries to access data from a different company
 * - Operation attempts to bypass company scoping
 * - Data isolation rules are violated
 */
@ResponseStatus(HttpStatus.FORBIDDEN)
public class CompanyIsolationViolationException extends RuntimeException {
    private String requestedCompanyCode;
    private String authorizedCompanyCode;

    public CompanyIsolationViolationException(String message) {
        super(message);
    }

    public CompanyIsolationViolationException(String message, String requestedCompanyCode, String authorizedCompanyCode) {
        super(message);
        this.requestedCompanyCode = requestedCompanyCode;
        this.authorizedCompanyCode = authorizedCompanyCode;
    }

    public CompanyIsolationViolationException(String message, Throwable cause) {
        super(message, cause);
    }

    public String getRequestedCompanyCode() {
        return requestedCompanyCode;
    }

    public String getAuthorizedCompanyCode() {
        return authorizedCompanyCode;
    }
}
