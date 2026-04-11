package com.sedcore.security.models.request;

import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @Size(max = 200)
        String displayName,

        /** "TR" | "EN" */
        String languageVal,

        /** Kasiyerler için mağaza ataması */
        String storeId,

        /** "USER" | "ADMIN" */
        String userType
) {}
