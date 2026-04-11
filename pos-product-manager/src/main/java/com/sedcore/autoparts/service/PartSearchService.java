package com.sedcore.autoparts.service;

import com.sedcore.autoparts.model.PartSearchResponse;

import java.util.List;

public interface PartSearchService {

    List<PartSearchResponse> searchParts(String keyword, String make, String model, Integer year);
}
