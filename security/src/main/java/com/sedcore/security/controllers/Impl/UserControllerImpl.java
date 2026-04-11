package com.sedcore.security.controllers.Impl;

import com.sedcore.security.controllers.IUserController;
import com.sedcore.security.models.request.*;
import com.sedcore.security.models.response.UserResponse;
import com.sedcore.security.services.IUserDefService;
import com.towpen.base.exceptions.ApiResponse;
import com.towpen.base.exceptions.TOpenException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Slf4j
public class UserControllerImpl implements IUserController {

    private final IUserDefService userDefService;

    // ── Listeleme ────────────────────────────────────────────────────────────

    @Override
    public ResponseEntity<ApiResponse<List<UserResponse>>> getAllUsers(String companyCode) {
        try {
            var users = userDefService.getAllUsers(companyCode);
            return ResponseEntity.ok(ApiResponse.success(users));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kullanıcılar listelenemedi", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Kullanıcılar yüklenemedi"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(userDefService.getUserById(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kullanıcı getirilemedi: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Kullanıcı getirilemedi"));
        }
    }

    // ── CRUD ─────────────────────────────────────────────────────────────────

    @Override
    public ResponseEntity<ApiResponse<UserResponse>> createUser(String companyCode, CreateUserRequest request) {
        try {
            var user = userDefService.createUser(companyCode, request);
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(user));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kullanıcı oluşturulamadı", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Kullanıcı oluşturulamadı"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(String id, UpdateUserRequest request) {
        try {
            return ResponseEntity.ok(ApiResponse.success(userDefService.updateUser(id, request)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kullanıcı güncellenemedi: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Kullanıcı güncellenemedi"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> deleteUser(String id) {
        try {
            userDefService.deleteUser(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kullanıcı silinemedi: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Kullanıcı silinemedi"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> toggleStatus(String id) {
        try {
            userDefService.toggleStatus(id);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Kullanıcı durumu değiştirilemedi: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Durum değiştirilemedi"));
        }
    }

    // ── Şifre ────────────────────────────────────────────────────────────────

    @Override
    public ResponseEntity<ApiResponse<Void>> changePassword(String id, ChangePasswordRequest request) {
        try {
            userDefService.changePassword(id, request);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Şifre değiştirilemedi: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Şifre değiştirilemedi"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> resetPassword(String id, ResetPasswordRequest request) {
        try {
            userDefService.resetPassword(id, request);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Şifre sıfırlanamadı: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Şifre sıfırlanamadı"));
        }
    }

    // ── Rol ──────────────────────────────────────────────────────────────────

    @Override
    public ResponseEntity<ApiResponse<Void>> assignRole(String id, String companyCode, AssignRoleRequest request) {
        try {
            userDefService.assignRole(id, request.roleCode(), companyCode);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Rol atanamadı: user={}, role={}", id, request.roleCode(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Rol atanamadı"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<Void>> removeRole(String id, String roleCode) {
        try {
            userDefService.removeRole(id, roleCode);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Rol kaldırılamadı: user={}, role={}", id, roleCode, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Rol kaldırılamadı"));
        }
    }

    @Override
    public ResponseEntity<ApiResponse<List<String>>> getRoles(String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(userDefService.getRoles(id)));
        } catch (TOpenException e) {
            throw e;
        } catch (Exception e) {
            log.error("Roller getirilemedi: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Roller getirilemedi"));
        }
    }
}
