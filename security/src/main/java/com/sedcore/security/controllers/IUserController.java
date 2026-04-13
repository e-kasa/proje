package com.sedcore.security.controllers;

import com.sedcore.security.models.request.*;
import com.sedcore.security.models.response.RoleResponse;
import com.sedcore.security.models.response.UserResponse;
import com.towpen.base.exceptions.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RequestMapping({"/api/users", "/api/v1/users"})   // v1 alias — backward compat
public interface IUserController {

    @GetMapping
    ResponseEntity<ApiResponse<List<UserResponse>>> getAllUsers(
            @RequestHeader(value = "X-Company-Code", required = false) String companyCode);

    @GetMapping("/{id}")
    ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable String id);

    @PostMapping
    ResponseEntity<ApiResponse<UserResponse>> createUser(
            @RequestHeader(value = "X-Company-Code", required = false) String companyCode,
            @RequestBody CreateUserRequest request);

    @PutMapping("/{id}")
    ResponseEntity<ApiResponse<UserResponse>> updateUser(
            @PathVariable String id,
            @RequestBody UpdateUserRequest request);

    @DeleteMapping("/{id}")
    ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable String id);

    @PatchMapping("/{id}/toggle-status")
    ResponseEntity<ApiResponse<Void>> toggleStatus(@PathVariable String id);

    @PostMapping("/{id}/change-password")
    ResponseEntity<ApiResponse<Void>> changePassword(
            @PathVariable String id,
            @RequestBody ChangePasswordRequest request);

    @PostMapping("/{id}/reset-password")
    ResponseEntity<ApiResponse<Void>> resetPassword(
            @PathVariable String id,
            @RequestBody ResetPasswordRequest request);

    @PostMapping("/{id}/roles")
    ResponseEntity<ApiResponse<Void>> assignRole(
            @PathVariable String id,
            @RequestHeader(value = "X-Company-Code", required = false) String companyCode,
            @RequestBody AssignRoleRequest request);

    @DeleteMapping("/{id}/roles/{roleCode}")
    ResponseEntity<ApiResponse<Void>> removeRole(
            @PathVariable String id,
            @PathVariable String roleCode);

    @GetMapping("/{id}/roles")
    ResponseEntity<ApiResponse<List<String>>> getRoles(@PathVariable String id);

    /** Firma'ya ait tüm rolleri döner — kullanıcı oluşturma formunda dropdown için */
    @GetMapping("/available-roles")
    ResponseEntity<ApiResponse<List<RoleResponse>>> getAvailableRoles(
            @RequestHeader(value = "X-Company-Code", required = false) String companyCode);
}
