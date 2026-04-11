package com.sedcore.service.impl;

import com.sedcore.context.CompanyContext;
import com.sedcore.entity.CompanySetting;
import com.sedcore.repository.CompanySettingRepository;
import com.sedcore.service.CompanySettingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class CompanySettingServiceImpl implements CompanySettingService {

    private final CompanySettingRepository companySettingRepository;

    private String companyCode() {
        String code = CompanyContext.get();
        return (code == null || code.isBlank()) ? "syste" : code;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<String, Object> getSettings() {
        return companySettingRepository.findFirstByCompanyCodeOrderByCreateTimeDesc(companyCode())
                .map(this::toMap)
                .orElse(emptySettings());
    }

    @Override
    public Map<String, Object> updateSettings(Map<String, Object> data) {
        String cc = companyCode();
        CompanySetting setting = companySettingRepository
                .findFirstByCompanyCodeOrderByCreateTimeDesc(cc)
                .orElse(CompanySetting.builder().build());

        if (data.containsKey("companyName")) setting.setCompanyName((String) data.get("companyName"));
        if (data.containsKey("taxNumber")) setting.setTaxNumber((String) data.get("taxNumber"));
        if (data.containsKey("taxOffice")) setting.setTaxOffice((String) data.get("taxOffice"));
        if (data.containsKey("phone")) setting.setPhone((String) data.get("phone"));
        if (data.containsKey("email")) setting.setEmail((String) data.get("email"));
        if (data.containsKey("address")) setting.setAddress((String) data.get("address"));
        if (data.containsKey("city")) setting.setCity((String) data.get("city"));
        if (data.containsKey("country")) setting.setCountry((String) data.get("country"));
        if (data.containsKey("website")) setting.setWebsite((String) data.get("website"));
        if (data.containsKey("logoUrl")) setting.setLogoUrl((String) data.get("logoUrl"));
        if (data.containsKey("currency")) setting.setCurrency((String) data.get("currency"));
        if (data.containsKey("sectorType")) setting.setSectorType((String) data.get("sectorType"));

        companySettingRepository.save(setting);
        log.info("Firma ayarları güncellendi: {}", cc);
        return toMap(setting);
    }

    private Map<String, Object> toMap(CompanySetting s) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", s.getId());
        map.put("companyName", s.getCompanyName());
        map.put("taxNumber", s.getTaxNumber());
        map.put("taxOffice", s.getTaxOffice());
        map.put("phone", s.getPhone());
        map.put("email", s.getEmail());
        map.put("address", s.getAddress());
        map.put("city", s.getCity());
        map.put("country", s.getCountry());
        map.put("website", s.getWebsite());
        map.put("logoUrl", s.getLogoUrl());
        map.put("currency", s.getCurrency());
        map.put("sectorType", s.getSectorType());
        return map;
    }

    private Map<String, Object> emptySettings() {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("companyName", null);
        map.put("taxNumber", null);
        map.put("taxOffice", null);
        map.put("phone", null);
        map.put("email", null);
        map.put("address", null);
        map.put("city", null);
        map.put("country", "Türkiye");
        map.put("website", null);
        map.put("logoUrl", null);
        map.put("currency", "TRY");
        map.put("sectorType", null);
        return map;
    }
}
