package com.sedcore.security.controllers.Impl;

import com.sedcore.security.models.request.CompanyRegistrationRequest;
import com.sedcore.security.services.ICompanyRegistrationService;
import com.towpen.base.restservice.model.RestRootEntity;
import com.towpen.base.security.JWT;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class RestCompanyRegistrationControllerImpl {

    private final ICompanyRegistrationService registrationService;

    @PostMapping("/register/company")
    public RestRootEntity<JWT> registerCompany(@RequestBody CompanyRegistrationRequest request) {
        return RestRootEntity.ok(registrationService.registerCompany(request));
    }
}
