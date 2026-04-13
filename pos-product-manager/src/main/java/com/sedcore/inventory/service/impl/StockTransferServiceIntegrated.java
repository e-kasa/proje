package com.sedcore.inventory.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.inventory.entity.StockMovement;
import com.sedcore.inventory.entity.StockTransfer;
import com.sedcore.common.enums.StockMovementType;
import com.sedcore.inventory.model.StockTransferItemRequest;
import com.sedcore.inventory.model.StockTransferRequest;
import com.sedcore.inventory.service.StockLevelService;
import com.sedcore.product.repository.ProductVariantRepository;
import com.sedcore.inventory.repository.StockMovementRepository;
import com.sedcore.inventory.repository.StockTransferRepository;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.security.ISessionInstanceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * ENTEGRE TRANSFER SERVICE
 * Lokasyonlar arası ürün transferi (Store ↔ Warehouse, Store ↔ Store, Warehouse ↔ Warehouse).
 *
 * Akış:
 * 1. StockTransfer kaydı oluştur
 * 2. Her kalem: StockLevel.deductStock(kaynak) — yetersizse exception
 * 3. Her kalem: TRANSFER_OUT hareketi (audit)
 * 4. Her kalem: StockLevel.addStock(hedef)
 * 5. Her kalem: TRANSFER_IN hareketi (audit)
 *
 * Tüm adımlar tek @Transactional içinde — hepsi başarılı olur ya da hiçbiri.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockTransferServiceIntegrated {

    private final StockTransferRepository stockTransferRepository;
    private final StockMovementRepository stockMovementRepository;
    private final ProductVariantRepository variantRepository;
    private final StockLevelService stockLevelService;
    @Autowired private ISessionInstanceService sessionInstanceService;

    @Transactional
    public StockTransfer createTransfer(StockTransferRequest request) {
        log.info("Transfer başlatılıyor: {} ({}) → {} ({})",
                request.getFromLocationId(), request.getFromLocationType(),
                request.getToLocationId(), request.getToLocationType());

        // 1. TRANSFER KAYDI
        StockTransfer transfer = new StockTransfer();
        transfer.setFromLocationId(request.getFromLocationId());
        transfer.setFromLocationType(request.getFromLocationType());
        transfer.setToLocationId(request.getToLocationId());
        transfer.setToLocationType(request.getToLocationType());
        transfer.setNotes(request.getNotes());
        transfer = prepareAndSave(stockTransferRepository, transfer);
        log.info("StockTransfer kaydedildi: ID={}", transfer.getId());

        List<StockMovement> movements = new ArrayList<>();

        for (StockTransferItemRequest item : request.getItems()) {
            ProductVariant variant = variantRepository.findById(item.getVariantId())
                    .orElseThrow(() -> new RuntimeException("Varyant bulunamadı: " + item.getVariantId()));

            // 2. StockLevel: kaynaktan düş (yetersizse BusinessException)
            stockLevelService.deductStock(variant.getId(), request.getFromLocationId(), item.getQuantity());

            // 3. TRANSFER_OUT hareketi (audit kaydı)
            StockMovement out = StockMovement.builder()
                    .variant(variant)
                    .locationId(request.getFromLocationId())
                    .locationType(request.getFromLocationType())
                    .movementType(StockMovementType.TRANSFER_OUT)
                    .quantity(item.getQuantity())
                    .transfer(transfer)
                    .build();
            movements.add(prepareAndSave(stockMovementRepository, out));

            // 4. StockLevel: hedefe ekle
            stockLevelService.addStock(variant.getId(), request.getToLocationId(),
                    request.getToLocationType(), item.getQuantity());

            // 5. TRANSFER_IN hareketi (audit kaydı)
            StockMovement in = StockMovement.builder()
                    .variant(variant)
                    .locationId(request.getToLocationId())
                    .locationType(request.getToLocationType())
                    .movementType(StockMovementType.TRANSFER_IN)
                    .quantity(item.getQuantity())
                    .transfer(transfer)
                    .build();
            movements.add(prepareAndSave(stockMovementRepository, in));

            log.info("Transfer: Variant={}, Miktar={}, {} → {}",
                    variant.getSku(), item.getQuantity(),
                    request.getFromLocationId(), request.getToLocationId());
        }

        transfer.setMovements(movements);
        log.info("Transfer tamamlandı: ID={}, {} hareket", transfer.getId(), movements.size());
        return transfer;
    }

    private <E extends TOpenSimpleCompanyEntity> E prepareAndSave(
            org.springframework.data.repository.CrudRepository<E, String> repo, E entity) {
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) companyCode = "SYSTEM";
        if (entity.getCompanyCode() == null || entity.getCompanyCode().isBlank()) {
            entity.setCompanyCode(companyCode);
        }
        if (entity.getCreateTime() == null) {
            entity.setCreateTime(java.util.Calendar.getInstance().getTime());
        }
        if (entity.getCreateUser() == null || entity.getCreateUser().isBlank()) {
            String userCode = null;
            try { userCode = sessionInstanceService.getUserCode(); } catch (Exception ignored) {}
            entity.setCreateUser(userCode != null && !userCode.isBlank() ? userCode : "SYSTEM");
        }
        return repo.save(entity);
    }
}
