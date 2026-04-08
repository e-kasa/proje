package com.sedcore.security.services;

import com.sedcore.security.models.request.CompanyRegistrationRequest;
import com.towpen.base.security.JWT;

public interface ICompanyRegistrationService {
    JWT registerCompany(CompanyRegistrationRequest request);
}
