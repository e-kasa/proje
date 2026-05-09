package com.sedcore.customer.service;

import com.sedcore.customer.entity.CustomerVehicle;
import com.sedcore.customer.model.CustomerVehicleDto;
import com.sedcore.customer.model.CustomerVehicleResponse;
import com.sedcore.customer.model.VehicleSearchResponse;

import java.util.List;
import java.util.Optional;

/**
 * Sprint 9 — CustomerVehicle service interface.
 *
 * <p>@Service annotated impl AOP CompanyHibernateFilterActivator pointcut'ına
 * uyar (com.sedcore..service..*) → tenant filter aktif olur.
 */
public interface CustomerVehicleService {

    /** Müşterinin aktif plakaları (UI dropdown için). */
    List<CustomerVehicleResponse> listByCustomer(String customerId);

    /** Plaka prefix arama (autocomplete). */
    List<CustomerVehicleResponse> searchByCustomer(String customerId, String q);

    /** Tek kayıt. */
    Optional<CustomerVehicleResponse> findById(String id);

    /** Entity getter — Sale.createSale içinde FK kullanmak için. */
    CustomerVehicle getEntity(String id);

    /** Yeni plaka kaydı (idempotent: aynı normalized varsa mevcut döner). */
    CustomerVehicleResponse create(String customerId, CustomerVehicleDto dto);

    CustomerVehicleResponse update(String id, CustomerVehicleDto dto);

    /** Soft-delete (isActive=false). */
    CustomerVehicleResponse deactivate(String id);

    /**
     * Sprint 11e — Tenant-wide plaka prefix arama (customerId yok).
     * Her sonuç müşteri ismi + açık satış count + açık tutar içerir.
     * Limit varsayılan 20.
     */
    List<VehicleSearchResponse> searchAcrossTenant(String q, int limit);
}
