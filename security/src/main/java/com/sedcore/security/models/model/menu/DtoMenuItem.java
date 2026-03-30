package com.sedcore.security.models.model.menu;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.Data;

@Data
public class DtoMenuItem extends DtoBaseModel {
    private String label;
    private String link;
}
