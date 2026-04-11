package com.sedcore.security.models.response;

import lombok.Builder;

import java.util.List;

/**
 * Kullanıcı bilgisi — okuma amaçlı Java 25 Record.
 */
@Builder
public record UserResponse(
        String id,
        String userName,
        String displayName,
        String companyCode,
        String languageVal,
        Boolean isActive,
        String storeId,
        String userType,
        Boolean canLogin,
        List<String> roles
) {}
