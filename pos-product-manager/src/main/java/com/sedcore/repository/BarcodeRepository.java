package com.sedcore.repository;

import com.sedcore.entity.Barcode;
import com.sedcore.model.BarcodeResponse;
import com.towpen.base.db.repository.BaseDaoRepository;
import jakarta.validation.constraints.NotBlank;
import org.apache.logging.log4j.util.Lazy;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BarcodeRepository extends BaseDaoRepository<Barcode> {

    List<Barcode> findByVariantId(String id);

    boolean existsByBarcodeCode(@NotBlank(message = "Barkod kodu zorunludur") String barcodeCode);
@Query("SELECT pr FROM Barcode pr where pr.barcodeCode=:code")
    Optional<BarcodeResponse> findByBarcodeCode(String code);
}
