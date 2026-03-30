package com.sedcore.controller;

import com.sedcore.model.UnitRequest;
import com.sedcore.model.UnitResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

public interface UnitController {

    ResponseEntity<ApiResponse<List<UnitResponse>>> getActiveUnits();

    ResponseEntity<ApiResponse<List<UnitResponse>>> getAllUnits();

    ResponseEntity<ApiResponse<UnitResponse>> createUnit(@RequestBody UnitRequest request);

    ResponseEntity<ApiResponse<UnitResponse>> updateUnit(@PathVariable String id, @RequestBody UnitRequest request);

    ResponseEntity<ApiResponse<Void>> deleteUnit(@PathVariable String id);

    ResponseEntity<ApiResponse<UnitResponse>> toggleStatus(@PathVariable String id);
}
