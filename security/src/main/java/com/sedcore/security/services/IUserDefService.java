package com.sedcore.security.services;

import com.sedcore.security.models.request.*;
import com.sedcore.security.models.response.RoleResponse;
import com.sedcore.security.models.response.UserResponse;
import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.security.BaseDbService;
import com.towpen.base.security.model.TOpenSessionInstance;

import java.util.List;

public interface IUserDefService extends BaseDbService<UserDef> {

    // ── Auth ─────────────────────────────────────────────────────────────────
    TOpenSessionInstance login(String userName, String password);

    // ── Listeleme ────────────────────────────────────────────────────────────
    List<UserResponse> getAllUsers(String companyCode);
    UserResponse getUserById(String userId);

    // ── CRUD ─────────────────────────────────────────────────────────────────
    UserResponse createUser(String companyCode, CreateUserRequest request);
    UserResponse updateUser(String userId, UpdateUserRequest request);
    void deleteUser(String userId);
    void toggleStatus(String userId);

    // ── Şifre ────────────────────────────────────────────────────────────────
    void changePassword(String userId, ChangePasswordRequest request);
    void resetPassword(String userId, ResetPasswordRequest request);

    // ── Rol ──────────────────────────────────────────────────────────────────
    void assignRole(String userId, String roleCode, String companyCode);
    void removeRole(String userId, String roleCode);
    List<String> getRoles(String userId);

    // ── Firma Rolleri ─────────────────────────────────────────────────────────
    List<RoleResponse> getRolesForCompany(String companyCode);
}
