package com.sedcore.controller.impl;

import com.sedcore.entity.Sale;
import com.sedcore.model.SaleRequest;
import com.sedcore.repository.SaleRepository;
import com.sedcore.se.ApiResponse;
import com.sedcore.service.SaleService;
import com.sedcore.service.impl.SaleServiceIntegrated;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/sales")
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
                sales = (List<Sale>)saleRepository.findAll();
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

    // PATCH /product/api/v1/sales/{id}/cancel
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Map<String, Object>>> cancel(@PathVariable String id) {
        try {
            Sale sale = saleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Satış bulunamadı: " + id));
            sale.setIsCancelled(true);
            sale = saleRepository.save(sale);
            log.info("Satış iptal edildi: {}", sale.getSaleNumber());
            return ResponseEntity.ok(ApiResponse.success(toMap(sale)));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    // GET /product/api/v1/sales/stats
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            var all = (List<Sale>)saleRepository.findAll();
            Map<String, Object> s = new HashMap<>();
            s.put("totalSales", all.size());
            s.put("activeSales", all.stream().filter(sale -> !Boolean.TRUE.equals(sale.getIsCancelled())).count());
            s.put("cancelledSales", all.stream().filter(sale -> Boolean.TRUE.equals(sale.getIsCancelled())).count());
            s.put("totalRevenue", all.stream()
                .filter(sale -> !Boolean.TRUE.equals(sale.getIsCancelled()))
                .map(Sale::getTotalAmount)
                .reduce(java.math.BigDecimal.ZERO, java.math.BigDecimal::add));
            return ResponseEntity.ok(ApiResponse.success(s));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    private Map<String, Object> toMap(Sale s) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", s.getId());
        m.put("saleNumber", s.getSaleNumber());
        m.put("saleDate", s.getSaleDate());
        m.put("totalAmount", s.getTotalAmount());
        m.put("paidAmount", s.getPaidAmount());
        m.put("remainingAmount", s.getRemainingAmount());
        m.put("isCancelled", s.getIsCancelled());
        m.put("notes", s.getNotes());
        m.put("companyCode", s.getCompanyCode());
        if (s.getCustomer() != null) {
            m.put("customerId", s.getCustomer().getId());
            m.put("customerName", s.getCustomer().getName());
        } else {
            m.put("customerId", null);
            m.put("customerName", null);
        }
        return m;
    }
}
