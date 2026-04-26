package com.sedcore.customer.service.impl;

import com.sedcore.autoparts.entity.Vehicle;
import com.sedcore.common.context.CompanyContext;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerVehicle;
import com.sedcore.customer.model.CustomerVehicleDto;
import com.sedcore.customer.model.CustomerVehicleResponse;
import com.sedcore.customer.repository.CustomerVehicleRepository;
import com.sedcore.customer.service.CustomerService;
import com.sedcore.customer.service.CustomerVehicleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Calendar;
import java.util.List;
import java.util.Optional;

/**
 * Sprint 9 — CustomerVehicle servis implementasyonu.
 *
 * <p>@Service → AOP CompanyHibernateFilterActivator advice tetiklenir → tenant filter aktif.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CustomerVehicleServiceImpl implements CustomerVehicleService {

    private final CustomerVehicleRepository repo;
    private final CustomerService customerService;

    @Override
    @Transactional(readOnly = true)
    public List<CustomerVehicleResponse> listByCustomer(String customerId) {
        return repo.findByCustomerIdAndIsActiveOrderByPlateDisplay(customerId, true)
                .stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<CustomerVehicleResponse> searchByCustomer(String customerId, String q) {
        if (q == null || q.isBlank()) return listByCustomer(customerId);
        String normalized = CustomerVehicle.normalize(q);
        return repo.searchByCustomer(customerId, normalized)
                .stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<CustomerVehicleResponse> findById(String id) {
        return repo.findById(id).map(this::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public CustomerVehicle getEntity(String id) {
        return repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Plaka bulunamadi: " + id));
    }

    /**
     * Idempotent create: aynı (customer_id, plate_normalized) varsa mevcut döner;
     * yoksa yeni kayıt oluşturur. Bu, frontend "yeni plaka ekle" akışının
     * çift kayıt yaratmasını önler (kullanıcı aynı plakayı tekrar yazarsa).
     */
    @Override
    public CustomerVehicleResponse create(String customerId, CustomerVehicleDto dto) {
        String normalized = CustomerVehicle.normalize(dto.getPlateDisplay());
        if (normalized == null || normalized.isBlank()) {
            throw new IllegalArgumentException("Plaka boş olamaz");
        }

        // Idempotent: zaten varsa onu dön
        Optional<CustomerVehicle> existing =
                repo.findByCustomerIdAndPlateNormalized(customerId, normalized);
        if (existing.isPresent()) {
            log.info("CustomerVehicle zaten var (idempotent): customerId={}, plate={}",
                    customerId, normalized);
            return toResponse(existing.get());
        }

        Customer customer = customerService.getEntity(customerId);

        CustomerVehicle cv = CustomerVehicle.builder()
                .customer(customer)
                .plateDisplay(dto.getPlateDisplay().trim())
                .plateNormalized(normalized)
                .make(dto.getMake())
                .model(dto.getModel())
                .yearOfManufacture(dto.getYearOfManufacture())
                .notes(dto.getNotes())
                .isActive(dto.getIsActive() != null ? dto.getIsActive() : true)
                .build();

        // Multi-tenant: companyCode + audit
        String companyCode = CompanyContext.get();
        if (companyCode == null || companyCode.isBlank()) companyCode = customer.getCompanyCode();
        cv.setCompanyCode(companyCode);
        cv.setCreateUser("SYSTEM");
        cv.setCreateTime(Calendar.getInstance().getTime());

        CustomerVehicle saved = repo.save(cv);
        log.info("CustomerVehicle oluşturuldu: id={}, customerId={}, plate={}",
                saved.getId(), customerId, saved.getPlateNormalized());
        return toResponse(saved);
    }

    @Override
    public CustomerVehicleResponse update(String id, CustomerVehicleDto dto) {
        CustomerVehicle cv = getEntity(id);
        if (dto.getPlateDisplay() != null) {
            cv.setPlateDisplay(dto.getPlateDisplay().trim());
            cv.setPlateNormalized(CustomerVehicle.normalize(dto.getPlateDisplay()));
        }
        if (dto.getMake() != null) cv.setMake(dto.getMake());
        if (dto.getModel() != null) cv.setModel(dto.getModel());
        if (dto.getYearOfManufacture() != null) cv.setYearOfManufacture(dto.getYearOfManufacture());
        if (dto.getNotes() != null) cv.setNotes(dto.getNotes());
        if (dto.getIsActive() != null) cv.setIsActive(dto.getIsActive());
        return toResponse(repo.save(cv));
    }

    @Override
    public CustomerVehicleResponse deactivate(String id) {
        CustomerVehicle cv = getEntity(id);
        cv.setIsActive(false);
        return toResponse(repo.save(cv));
    }

    private CustomerVehicleResponse toResponse(CustomerVehicle cv) {
        Vehicle v = cv.getVehicle();
        return CustomerVehicleResponse.builder()
                .id(cv.getId())
                .customerId(cv.getCustomer() != null ? cv.getCustomer().getId() : null)
                .plateDisplay(cv.getPlateDisplay())
                .plateNormalized(cv.getPlateNormalized())
                .vehicleId(v != null ? v.getId() : null)
                .make(cv.getMake())
                .model(cv.getModel())
                .yearOfManufacture(cv.getYearOfManufacture())
                .notes(cv.getNotes())
                .isActive(cv.getIsActive())
                .companyCode(cv.getCompanyCode())
                .build();
    }
}
