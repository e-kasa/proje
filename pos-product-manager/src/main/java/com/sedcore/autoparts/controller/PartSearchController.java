package com.sedcore.autoparts.controller;

import com.sedcore.autoparts.model.PartSearchResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface PartSearchController {

    ResponseEntity<ApiResponse<List<PartSearchResponse>>> searchParts(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String make,
            @RequestParam(required = false) String model,
            @RequestParam(required = false) Integer year);
}
