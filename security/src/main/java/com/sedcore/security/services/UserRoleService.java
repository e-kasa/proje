package com.sedcore.security.services;

import com.sedcore.security.repos.UserRoleRepository;
import com.towpen.base.db.model.security.UserRole;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserRoleService {

    private final UserRoleRepository userRoleRepository;

    public UserRole saveRole(UserRole role)
    {
        userRoleRepository.save(role);
        return  role;
    }

    public List<UserRole> getAll()
    {
        return null;
    }

    public UserRole findById(String roleId){
        return null;//userRoleRepository.findById(Long.valueOf(roleId)).get();
    }
}
