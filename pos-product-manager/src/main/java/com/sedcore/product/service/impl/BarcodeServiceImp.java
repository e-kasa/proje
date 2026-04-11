package com.sedcore.product.service.impl;

import com.sedcore.product.entity.Barcode;
import com.sedcore.product.model.BarcodeResponse;
import com.sedcore.product.repository.BarcodeRepository;
import com.sedcore.product.service.BarcodeService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Slf4j
@Transactional
public class BarcodeServiceImp extends BaseDbServiceImp<BarcodeRepository, Barcode> implements BarcodeService {

    @Override
    public Class<?> getDTOClassForService() {
        return BarcodeResponse.class;
    }

    /**
     * Barcode Entity → BarcodeResponse mapping
     */
    public BarcodeResponse mapToResponse(Barcode barcode) {
        return BarcodeResponse.builder()
                .id(barcode.getId())
                .barcodeCode(barcode.getBarcodeCode())
                .barcodeType(barcode.getBarcodeType() != null ? barcode.getBarcodeType().name() : null)
                .isPrimary(barcode.getIsPrimary())
                .isActive(barcode.getIsActive())
                .usageCount(barcode.getUsageCount())
                .build();
    }

    /**
     * Barkod kodu ile barkod bul

    @Transactional(readOnly = true)
    public Optional<BarcodeResponse> findByBarcodeCode(String code) {
       dao.findByBarcodeCode(code)
                .map(this::mapToResponse);
       return to
    } */
}
