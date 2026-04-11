package com.sedcore.security.models.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank(message = "Yeni şifre zorunludur")
        @Size(min = 6, message = "Şifre en az 6 karakter olmalıdır")
        String newPassword
) {}
