package com.sedcore.service;

import com.sedcore.entity.CompanySetting;

import java.util.Map;

public interface CompanySettingService {
    Map<String, Object> getSettings();
    Map<String, Object> updateSettings(Map<String, Object> data);
}
