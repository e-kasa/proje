package com.sedcore.model.product;

import com.towpen.base.restservice.model.DtoCrudModel;
import jakarta.persistence.Column;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
public class DtoAttributeValueUI extends DtoCrudModel {
    private String attributeId;

    private String valueString;
    private BigDecimal valueNumber;

    private Boolean valueBoolean;

    private LocalDate valueDate;
}
