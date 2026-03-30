package com.sedcore.security.models.model.menu;

import com.towpen.base.restservice.model.DtoCrudModel;
import lombok.Data;

@Data
public class DtoMenuItemUI extends DtoCrudModel {
    private String label;
    private String link;
}
