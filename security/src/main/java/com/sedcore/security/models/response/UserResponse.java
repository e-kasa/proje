package com.sedcore.security.models.response;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Kullanıcı bilgisi — okuma amaçlı Response DTO.
 * DtoBaseModel extend ederek BaseDbServiceImp.toDTO() ile mapping desteği kazanır.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse extends DtoBaseModel {

    private String id;
    private String userName;
    private String displayName;
    private String companyCode;
    private String languageVal;
    private Boolean isActive;
    private String storeId;
    private String userType;
    private Boolean canLogin;
    private List<String> roles;
}
