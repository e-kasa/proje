package com.sedcore.finance.service;

import com.sedcore.finance.entity.Payment;
import com.sedcore.finance.model.PaymentRequest;
import com.sedcore.finance.model.PaymentResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface PaymentService extends BaseDbService<Payment> {

    /** Yeni ödeme oluştur (müşteri tahsilatı veya tedarikçi ödemesi) */
    PaymentResponse createPayment(PaymentRequest request);

    /** Tek ödeme getir */
    PaymentResponse getPayment(String id);

    /** Müşteriye ait tüm ödemeler */
    List<PaymentResponse> getByCustomer(String customerId);

    /** Tedarikçiye ait tüm ödemeler */
    List<PaymentResponse> getBySupplier(String supplierId);

    /** Satışa ait ödemeler */
    List<PaymentResponse> getBySale(String saleId);

    /** Satın almaya ait ödemeler */
    List<PaymentResponse> getByPurchase(String purchaseId);

    /** Ödemeyi iptal et */
    PaymentResponse cancelPayment(String id, String reason);

    /** Ödemeyi onayla (banka/havale ödemeleri için) */
    PaymentResponse verifyPayment(String id, String verifiedBy);

    /**
     * Hazır Payment entity'sini kaydet — hesap güncellemesi veya transaction oluşturmaz.
     * Servis orkestrasyonlarında (SupplierService.recordPayment vb.) kullanılır.
     */
    Payment savePayment(Payment payment);
}
