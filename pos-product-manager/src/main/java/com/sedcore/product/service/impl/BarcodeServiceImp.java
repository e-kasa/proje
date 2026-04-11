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
     * barcodeType enum→String dönüşümü toDTO() sonrası manuel eklenir.
     */
    public BarcodeResponse mapToResponse(Barcode barcode) {
        BarcodeResponse dto = toDTO(barcode);
        // BarcodeType enum → String (BeanUtils enum→String kopyalamaz)
        dto.setBarcodeType(barcode.getBarcodeType() != null ? barcode.getBarcodeType().name() : null);
        return dto;
    }

    @Transactional(readOnly = true)
    public java.util.Optional<BarcodeResponse> findByBarcodeCode(String code) {
        return dao.findByBarcodeCode(code).map(this::mapToResponse);
    }
}
