package com.sedcore.inventory.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.exception.BusinessException;
import com.sedcore.inventory.entity.StockLevel;
import com.sedcore.inventory.repository.StockLevelRepository;
import com.sedcore.inventory.service.StockLevelService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class StockLevelServiceImpl implements StockLevelService {

    private final StockLevelRepository stockLevelRepository;

    // ─── STOK EKLE ───────────────────────────────────────────────────────────

    @Override
    @Transactional
    public StockLevel addStock(String variantId, String locationId, String locationType, int qty) {
        if (qty <= 0) return getOrCreate(variantId, locationId, locationType);

        String companyCode = CompanyContext.get();

        // @Modifying atomic increment — race condition yok
        int updated = stockLevelRepository.incrementQuantity(variantId, locationId, companyCode, qty);

        if (updated == 0) {
            // Kayıt yok → oluştur ve set et
            StockLevel sl = getOrCreate(variantId, locationId, locationType);
            sl.setQuantity(sl.getQuantity() + qty);
            return stockLevelRepository.save(sl);
        }

        log.debug("Stok eklendi: variant={}, location={}, delta=+{}", variantId, locationId, qty);
        return stockLevelRepository.findByVariantIdAndLocationId(variantId, locationId)
                .orElseThrow();
    }

    // ─── STOK DÜŞ ────────────────────────────────────────────────────────────

    @Override
    @Transactional
    public StockLevel deductStock(String variantId, String locationId, int qty) {
        String companyCode = CompanyContext.get();

        // Pessimistic write lock — aynı anda iki satış aynı stoku çift harcamaz
        StockLevel sl = stockLevelRepository
                .findByVariantIdAndLocationIdForUpdate(variantId, locationId, companyCode)
                .orElseThrow(() -> new BusinessException(
                        "Stok kaydı bulunamadı. Lokasyon: " + locationId
                        + ", Varyant: " + variantId));

        int available = sl.getQuantity() != null ? sl.getQuantity() : 0;
        if (available < qty) {
            throw new BusinessException(String.format(
                    "Stok yetersiz! Mevcut: %d, İstenen: %d (Lokasyon: %s)",
                    available, qty, locationId));
        }

        sl.setQuantity(available - qty);
        StockLevel saved = stockLevelRepository.save(sl);
        log.debug("Stok düşüldü: variant={}, location={}, delta=-{}, kalan={}",
                variantId, locationId, qty, saved.getQuantity());
        return saved;
    }

    // ─── STOK SET ET (sayım düzeltmesi) ──────────────────────────────────────

    @Override
    @Transactional
    public StockLevel setStock(String variantId, String locationId, String locationType, int absoluteQty) {
        StockLevel sl = getOrCreate(variantId, locationId, locationType);
        int prev = sl.getQuantity() != null ? sl.getQuantity() : 0;
        sl.setQuantity(absoluteQty);
        StockLevel saved = stockLevelRepository.save(sl);
        log.info("Stok sayım düzeltmesi: variant={}, location={}, eski={}, yeni={}",
                variantId, locationId, prev, absoluteQty);
        return saved;
    }

    // ─── SORGULAR ────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public Integer getQuantity(String variantId, String locationId) {
        return stockLevelRepository.findByVariantIdAndLocationId(variantId, locationId)
                .map(StockLevel::getQuantity)
                .orElse(0);
    }

    @Override
    @Transactional(readOnly = true)
    public List<StockLevel> getByVariant(String variantId) {
        return stockLevelRepository.findByVariantId(variantId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<StockLevel> getByLocation(String locationId) {
        return stockLevelRepository.findByLocationId(locationId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<StockLevel> getCriticalStocks(String companyCode) {
        return stockLevelRepository.findCriticalStocks(companyCode);
    }

    @Override
    @Transactional(readOnly = true)
    public int getTotalQuantity(String variantId) {
        String companyCode = CompanyContext.get();
        Integer total = stockLevelRepository.sumQuantityByVariant(companyCode, variantId);
        return total != null ? total : 0;
    }

    @Override
    @Transactional
    public StockLevel updateMinQuantity(String variantId, String locationId, int minQuantity) {
        StockLevel sl = stockLevelRepository.findByVariantIdAndLocationId(variantId, locationId)
                .orElseThrow(() -> new BusinessException("Stok kaydı bulunamadı"));
        sl.setMinQuantity(minQuantity);
        return stockLevelRepository.save(sl);
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Integer> getLocationSummary(String locationId) {
        List<StockLevel> levels = stockLevelRepository.findByLocationId(locationId);
        Map<String, Integer> summary = new HashMap<>();
        for (StockLevel sl : levels) {
            summary.put(sl.getVariantId(), sl.getQuantity() != null ? sl.getQuantity() : 0);
        }
        return summary;
    }

    // ─── YARDIMCI ────────────────────────────────────────────────────────────

    /** Kayıt varsa döner, yoksa 0 quantity ile oluşturur */
    private StockLevel getOrCreate(String variantId, String locationId, String locationType) {
        return stockLevelRepository.findByVariantIdAndLocationId(variantId, locationId)
                .orElseGet(() -> {
                    String cc = CompanyContext.get();
                    StockLevel sl = StockLevel.builder()
                            .variantId(variantId)
                            .locationId(locationId)
                            .locationType(locationType != null ? locationType : "STORE")
                            .quantity(0)
                            .minQuantity(5)
                            .build();
                    sl.setCompanyCode(cc);
                    sl.setCreateTime(Calendar.getInstance().getTime());
                    sl.setCreateUser("SYSTEM");
                    return stockLevelRepository.save(sl);
                });
    }
}
