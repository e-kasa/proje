package com.sedcore.service;

import com.sedcore.model.PartSearchResponse;

import java.util.List;

public interface PartSearchService {

    List<PartSearchResponse> searchParts(String keyword, String make, String model, Integer year);
}
