package com.sedcore.hrm.controller.impl;

import com.sedcore.hrm.service.impl.HrmServiceImpl;
import com.sedcore.common.util.ExceptionMapper;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * İnsan Kaynakları Yönetimi
 * Context-path: /product  →  tam URL: /product/api/v1/hrm/**
 */
@RestController
@RequestMapping("api/v1/hrm")
@RequiredArgsConstructor
@Slf4j
public class HrmControllerImpl {

    private final HrmServiceImpl hrmService;

    // ─── Employees ───────────────────────────────────────────────────

    @GetMapping("/employees")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getEmployees(
            @RequestParam(required = false) String department,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search) {
        try {
            return ResponseEntity.ok(ApiResponse.success(
                    hrmService.getEmployees(department, status, search)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Çalışan listesi hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @GetMapping("/employees/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getEmployeeById(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(hrmService.getEmployeeById(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Çalışan detay hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping("/employees")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createEmployee(@RequestBody Map<String, Object> data) {
        try {
            return ResponseEntity.ok(ApiResponse.success(hrmService.createEmployee(data)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Çalışan oluşturma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    @PutMapping("/employees/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateEmployee(
            @PathVariable String id, @RequestBody Map<String, Object> data) {
        try {
            return ResponseEntity.ok(ApiResponse.success(hrmService.updateEmployee(id, data)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Çalışan güncelleme hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @DeleteMapping("/employees/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteEmployee(@PathVariable String id) {
        try {
            hrmService.deleteEmployee(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Çalışan silme hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    @PostMapping("/employees/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleStatus(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(hrmService.toggleStatus(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Çalışan durum değiştirme hatası: {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    // ─── Departments ─────────────────────────────────────────────────

    @GetMapping("/departments")
    public ResponseEntity<ApiResponse<List<String>>> getDepartments() {
        try {
            return ResponseEntity.ok(ApiResponse.success(hrmService.getDepartments()));
        } catch (Exception e) {
            log.error("Departman listesi hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    // ─── Stats ───────────────────────────────────────────────────────

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStats() {
        try {
            return ResponseEntity.ok(ApiResponse.success(hrmService.getStats()));
        } catch (Exception e) {
            log.error("HRM istatistik hatası", e);
            throw ExceptionMapper.map(e);
        }
    }
}
