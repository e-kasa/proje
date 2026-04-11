package com.sedcore.security.models.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CreateUserRequest(
        @NotBlank(message = "Kullanıcı adı zorunludur")
        @Size(min = 3, max = 40, message = "Kullanıcı adı 3-40 karakter olmalıdır")
        String userName,

        @NotBlank(message = "Ad Soyad zorunludur")
        @Size(max = 200)
        String displayName,

        @NotBlank(message = "Şifre zorunludur")
        @Size(min = 6, message = "Şifre en az 6 karakter olmalıdır")
        String password,

        /** "TR" | "EN" — varsayılan TR */
        String languageVal,

        /** Kasiyerler için mağaza ataması — null ise tüm mağazalara erişim */
        String storeId,

        /** "USER" | "ADMIN" — varsayılan USER */
        String userType,

        /** Atanacak rol kodları: ["KASIYER", "DEPO", ...] */
        List<String> roles
) {}
