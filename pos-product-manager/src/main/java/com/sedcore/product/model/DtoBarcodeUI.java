package com.sedcore.product.model;

import com.towpen.base.restservice.model.DtoCrudModel;
import jakarta.persistence.Column;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DtoBarcodeUI extends DtoCrudModel {

    private String code;

    private String barcodeType;

    private Boolean isActive = false;
}
