package com.sedcore.product.model;

import com.towpen.base.restservice.model.DtoCrudModel;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
public class DtoProductVariantUI extends DtoCrudModel {

    private String sku;

    private BigDecimal additionalPrice;

    private Boolean isActive = true;

    private List<DtoAttributeValueUI> variantAttributes;

    private List<DtoBarcodeUI> barcodes;

}
