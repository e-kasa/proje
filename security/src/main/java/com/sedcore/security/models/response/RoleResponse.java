package com.sedcore.security.models.response;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Firma'ya ait roller — kullanıcı atama formunda dropdown için kullanılır.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoleResponse extends DtoBaseModel {

    private String id;
    private String code;        // "ADMIN", "CASHIER", "WAREHOUSE", "STORE_ADMIN"
    private String name;        // Görünen ad
    private String description;
    private Boolean isActive;
}
