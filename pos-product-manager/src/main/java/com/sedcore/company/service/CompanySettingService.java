package com.sedcore.company.service;

import com.sedcore.company.entity.CompanySetting;

import java.util.Map;

public interface CompanySettingService {
    Map<String, Object> getSettings();
    Map<String, Object> updateSettings(Map<String, Object> data);
}
