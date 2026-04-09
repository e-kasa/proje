package com.sedcore.controller.impl;

import com.sedcore.entity.Sale;
import com.sedcore.entity.StockMovement;
import com.sedcore.entity.ProductVariant;
import com.sedcore.enums.StockMovementType;
import com.sedcore.model.SaleRequest;
import com.sedcore.model.SaleReturnRequest;
import com.sedcore.model.SaleReturnResponse;
import com.sedcore.repository.SaleRepository;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.SaleService;
import com.sedcore.service.impl.SaleServiceIntegrated;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/product/api/v1/sales")
@RequiredArgsConstructor
@Slf4j
public class SaleControllerImpl {

    private final SaleService saleRepository;
    private final SaleServiceIntegrated saleService;

    // GET /product/api/v1/sales
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) String customerId,
            @RequestParam(required = false) Boolean isCancelled
    ) {
        try {
            List<Sale> sales;
            if (customerId != null) {
                sales = saleRepository.findByCustomerId(customerId);
            } else {
                sales = (List<Sale>) saleRepository.findAll();
            }
            var filtered = sales.stream()
                .filter(s -> isCancelled == null || isCancelled.equals(s.getIsCancelled()))
                .map(this::toMap)
                .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(filtered));
        } catch (Exception e) {
            log.error("Satış listesi hatası: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Satış listesi alınamadı: " + e.getMessage()));
        }
    }

    // GET /product/api/v1/sales/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            var sale = saleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Satış bulunamadı: " + id));
            return ResponseEntity.ok(ApiResponse.success(toMap(sale)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // GET /product/api/v1/sales/by-number/{saleNumber}
    @GetMapping("/by-number/{saleNumber}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getByNumber(@PathVariable String saleNumber) {
        try {
            var sale = saleRepository.findBySaleNumber(saleNumber)
                .orElseThrow(() -> new RuntimeException("Satış bulunamadı: " + saleNumber));
            return ResponseEntity.ok(ApiResponse.success(toMap(sale)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // POST /product/api/v1/sales
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(@Valid @RequestBody SaleRequest request) {
        try {
            Sale sale = saleService.createSale(request);
            log.info("Satış oluşturuldu: {}", sale.getSaleNumber());
            return ResponseEntity.ok(ApiResponse.success(toMap(sale)));
        } catch (Exception e) {
            log.error("Satış oluşturma hatası: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error("Satış oluşturulamadı: " + e.getMessage()));
        }
    }

    // POST /product/api/v1/sales/{id}/returns
    @PostMapping("/{id}/returns")
    public ResponseEntity<ApiResponse<SaleReturnResponse>> createReturn(
            @PathVariable String id,
            @RequestBody SaleReturnRequest request) {
        try {
            SaleReturnResponse response = saleService.createSaleReturn(id, request);
            log.info("Satis iadesi olusturuldu: saleId={}, tutar={}", id, response.getTotalReturnAmount());
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Satis iadesi hatasi: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Iade olusturulamadi: " + e.getMessage()));
        }
    }

    // PATCH /product/api/v1/sales/{id}/cancel
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Map<String, Object>>> cancel(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = (body != null && body.get("reason") != null)
                    ? body.get("reason") : "Belirtilmedi";
            Sale sale = saleService.cancelSale(id, reason);
            log.info("Satış iptal edildi: {}", sale.getSaleNumber());
            return ResponseEntity.ok(ApiResponse.success(toMap(sale)));
        } catch (Exception e) {
            log.error("Satış iptal hatası: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // GET /product/api/v1/sales/stats
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            var all = (List<Sale>) saleRepository.findAll();
            Map<String, Object> s = new HashMap<>();
            s.put("totalSales", all.size());
            s.put("activeSales", all.stream()
                    .filter(sale -> !Boolean.TRUE.equals(sale.getIsCancelled())).count());
            s.put("cancelledSales", all.stream()
                    .filter(sale -> Boolean.TRUE.equals(sale.getIsCancelled())).count());
            s.put("salesWithReturn", all.stream()
                    .filter(sale -> Boolean.TRUE.equals(sale.getHasReturn())).count());
            s.put("totalRevenue", all.stream()
                .filter(sale -> !Boolean.TRUE.equals(sale.getIsCancelled()))
                .map(Sale::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add));
            return ResponseEntity.ok(ApiResponse.success(s));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // ─── toMap ───────────────────────────────────────────────────────────────

    private Map<String, Object> toMap(Sale s) {
        Map<String, Object> m = new HashMap<>();
        m.put("id",              s.getId());
        m.put("saleNumber",      s.getSaleNumber());
        m.put("saleDate",        s.getSaleDate());
        m.put("totalAmount",     s.getTotalAmount());
        m.put("paidAmount",      s.getPaidAmount());
        m.put("remainingAmount", s.getRemainingAmount());
        m.put("isCancelled",     s.getIsCancelled());
        m.put("cancelReason",    s.getCancelReason());
        m.put("cancelDate",      s.getCancelDate());
        m.put("returnedAmount",  s.getReturnedAmount());
        m.put("hasReturn",       Boolean.TRUE.equals(s.getHasReturn()));
        m.put("notes",           s.getNotes());
        m.put("companyCode",     s.getCompanyCode());

        // Hesaplanan durum — Flutter filtre chip'leri için
        String status;
        if (Boolean.TRUE.equals(s.getIsCancelled())) {
            status = "cancelled";
        } else if (s.getRemainingAmount() != null
                && s.getRemainingAmount().compareTo(BigDecimal.ZERO) > 0) {
            status = "pending";   // Veresiye
        } else {
            status = "paid";
        }
        m.put("status", status);

        if (s.getCustomer() != null) {
            m.put("customerId",   s.getCustomer().getId());
            m.put("customerName", s.getCustomer().getName());
        } else {
            m.put("customerId",   null);
            m.put("customerName", null);
        }

        // Satış kalemleri — SALE_OUT hareketlerinden üret
        List<Map<String, Object>> items = new ArrayList<>();
        boolean hasReturn = false;
        if (s.getMovements() != null) {
            for (StockMovement mv : s.getMovements()) {
                if (mv == null) continue;
                if (mv.getMovementType() == StockMovementType.SALE_RETURN_IN) {
                    hasReturn = true;
                    continue;
                }
                if (mv.getMovementType() != StockMovementType.SALE_OUT) continue;
                ProductVariant v = mv.getVariant();
                BigDecimal unitPrice = mv.getUnitPrice() != null
                        ? mv.getUnitPrice() : BigDecimal.ZERO;
                int qty = mv.getQuantity() != null ? mv.getQuantity() : 0;

                Map<String, Object> item = new HashMap<>();
                item.put("movementId",   mv.getId());
                item.put("productId",    v != null ? v.getId()   : null);
                item.put("variantId",    v != null ? v.getId()   : null);
                item.put("variantSku",   v != null ? v.getSku()  : null);
                item.put("variantName",  v != null ? v.getName() : null);
                item.put("productName",  v != null && v.getProduct() != null
                        ? v.getProduct().getName() : null);
                item.put("quantity",     qty);
                item.put("unitPrice",    unitPrice);
                item.put("lineTotal",    unitPrice.multiply(BigDecimal.valueOf(qty)));
                item.put("discountRate", BigDecimal.ZERO);
                item.put("taxRate",      null);
                items.add(item);
            }
        }
        m.put("items",     items);
        m.put("itemCount", items.size());
        // hasReturn: entity flag'i önce, yoksa movement'lardan hesaplanan
        m.put("hasReturn", Boolean.TRUE.equals(s.getHasReturn()) || hasReturn);
        return m;
    }
}
