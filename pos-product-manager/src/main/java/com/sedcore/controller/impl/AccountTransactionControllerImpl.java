package com.sedcore.controller.impl;

import com.sedcore.controller.AccountTransactionController;
import com.sedcore.enums.TransactionType;
import com.sedcore.model.AccountTransactionResponse;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.service.AccountTransactionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;

import java.util.List;
import java.util.Map;

/**
 * Cari Hesap Hareketleri Controller
 *
 * GET  /product/api/v1/account-transactions/{id}                     → Tek hareket
 * GET  /product/api/v1/account-transactions?supplierId=&type=        → Tedarikçi hareketleri
 * GET  /product/api/v1/account-transactions?customerId=              → Müşteri hareketleri
 * GET  /product/api/v1/account-transactions?purchaseId=              → Satın alma hareketleri
 * PATCH /product/api/v1/account-transactions/{id}/cancel             → Hareket iptali
 */
@RestController
@RequestMapping("api/v1/account-transactions")
@RequiredArgsConstructor
@Slf4j
public class AccountTransactionControllerImpl implements AccountTransactionController {

    private final AccountTransactionService accountTransactionService;

    // GET /product/api/v1/account-transactions/{id}
    @Override
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AccountTransactionResponse>> getById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(accountTransactionService.getById(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Cari hareket getirme hatasi: id={}, {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    /**
     * Filtrelenmiş liste:
     *   ?supplierId=xxx           → Tedarikçi hareketleri
     *   ?supplierId=xxx&type=PURCHASE → Tipe göre filtreli
     *   ?customerId=xxx           → Müşteri hareketleri
     *   ?purchaseId=xxx           → Satın alma hareketleri
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> list(
            @RequestParam(required = false) String supplierId,
            @RequestParam(required = false) String customerId,
            @RequestParam(required = false) String purchaseId,
            @RequestParam(required = false) TransactionType type
    ) {
        try {
            if (supplierId != null && type != null) {
                return ResponseEntity.ok(ApiResponse.success(
                        accountTransactionService.getBySupplierAndType(supplierId, type)));
            }
            if (supplierId != null) {
                return ResponseEntity.ok(ApiResponse.success(
                        accountTransactionService.getBySupplier(supplierId)));
            }
            if (customerId != null) {
                return ResponseEntity.ok(ApiResponse.success(
                        accountTransactionService.getByCustomer(customerId)));
            }
            if (purchaseId != null) {
                return ResponseEntity.ok(ApiResponse.success(
                        accountTransactionService.getByPurchase(purchaseId)));
            }
            throw new TOpenException(new TOpenMessage(TMessageType.ACCOUNT_TRANSACTION_LIST_ERROR_2200));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Cari hareket listesi hatasi: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET (interface metodu — list() ile karşılanır, bu yüzden delegate et)
    @Override
    public ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> listBySupplier(
            String supplierId, TransactionType type) {
        return list(supplierId, null, null, type);
    }

    @Override
    public ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> listByCustomer(
            String customerId) {
        return list(null, customerId, null, null);
    }

    @Override
    public ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> listByPurchase(
            String purchaseId) {
        return list(null, null, purchaseId, null);
    }

    // PATCH /product/api/v1/account-transactions/{id}/cancel
    @Override
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<AccountTransactionResponse>> cancel(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String reason = body != null ? body.get("reason") : null;
            return ResponseEntity.ok(ApiResponse.success(
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Operation error: {}", e);
            throw ExceptionMapper.map(e);
        }
    }

}
