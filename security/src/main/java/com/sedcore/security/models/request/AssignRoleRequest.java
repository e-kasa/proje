package com.sedcore.security.models.request;

import jakarta.validation.constraints.NotBlank;

public record AssignRoleRequest(
        @NotBlank(message = "Rol kodu zorunludur")
        String roleCode
) {}
