package com.sedcore.hrm.service.impl;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.hrm.entity.Employee;
import com.sedcore.hrm.repository.EmployeeRepository;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
@RequiredArgsConstructor
public class HrmServiceImpl {

    private final EmployeeRepository employeeRepository;

    private String cc() {
        String code = CompanyContext.get();
        return (code == null || code.isBlank()) ? "syste" : code;
    }

    // ─── Employees ───────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getEmployees(String department, String status, String search) {
        List<Employee> employees;

        if (department != null && !department.isBlank()) {
            employees = employeeRepository.findByCompanyCodeAndDepartmentAndIsDeletedFalse(cc(), department);
        } else if (status != null && !status.isBlank()) {
            employees = employeeRepository.findByCompanyCodeAndStatusAndIsDeletedFalse(cc(), status);
        } else {
            employees = employeeRepository.findByCompanyCodeAndIsDeletedFalseOrderByFirstNameAsc(cc());
        }

        if (search != null && !search.isBlank()) {
            String q = search.toLowerCase();
            employees = employees.stream()
                    .filter(e -> (e.getFirstName() + " " + e.getLastName()).toLowerCase().contains(q)
                            || (e.getEmail() != null && e.getEmail().toLowerCase().contains(q))
                            || (e.getPosition() != null && e.getPosition().toLowerCase().contains(q)))
                    .collect(Collectors.toList());
        }

        return employees.stream().map(this::toMap).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getEmployeeById(String id) {
        return employeeRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, cc())
                .map(this::toMap)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
    }

    public Map<String, Object> createEmployee(Map<String, Object> data) {
        Employee employee = Employee.builder()
                .firstName(str(data, "firstName"))
                .lastName(str(data, "lastName"))
                .email(str(data, "email"))
                .phone(str(data, "phone"))
                .department(str(data, "department"))
                .position(str(data, "position"))
                .nationalId(str(data, "nationalId"))
                .address(str(data, "address"))
                .status(data.get("status") != null ? str(data, "status") : "ACTIVE")
                .build();

        if (data.get("salary") != null) {
            employee.setSalary(new java.math.BigDecimal(data.get("salary").toString()));
        }
        if (data.get("hireDate") != null) {
            employee.setHireDate(java.time.LocalDate.parse(data.get("hireDate").toString().substring(0, 10)));
        }

        employeeRepository.save(employee);
        log.info("Çalışan oluşturuldu: {} {} ({})", employee.getFirstName(), employee.getLastName(), employee.getId());
        return toMap(employee);
    }

    public Map<String, Object> updateEmployee(String id, Map<String, Object> data) {
        Employee employee = employeeRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, cc())
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        if (data.containsKey("firstName")) employee.setFirstName(str(data, "firstName"));
        if (data.containsKey("lastName"))  employee.setLastName(str(data, "lastName"));
        if (data.containsKey("email"))     employee.setEmail(str(data, "email"));
        if (data.containsKey("phone"))     employee.setPhone(str(data, "phone"));
        if (data.containsKey("department"))employee.setDepartment(str(data, "department"));
        if (data.containsKey("position"))  employee.setPosition(str(data, "position"));
        if (data.containsKey("nationalId"))employee.setNationalId(str(data, "nationalId"));
        if (data.containsKey("address"))   employee.setAddress(str(data, "address"));
        if (data.containsKey("status"))    employee.setStatus(str(data, "status"));
        if (data.containsKey("salary") && data.get("salary") != null) {
            employee.setSalary(new java.math.BigDecimal(data.get("salary").toString()));
        }
        if (data.containsKey("hireDate") && data.get("hireDate") != null) {
            employee.setHireDate(java.time.LocalDate.parse(data.get("hireDate").toString().substring(0, 10)));
        }
        employeeRepository.save(employee);
        return toMap(employee);
    }

    public void deleteEmployee(String id) {
        Employee employee = employeeRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, cc())
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
        employee.setIsDeleted(true);
        employeeRepository.save(employee);
        log.info("Çalışan silindi: {}", id);
    }

    public Map<String, Object> toggleStatus(String id) {
        Employee employee = employeeRepository.findByIdAndCompanyCodeAndIsDeletedFalse(id, cc())
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
        employee.setStatus("ACTIVE".equals(employee.getStatus()) ? "INACTIVE" : "ACTIVE");
        employeeRepository.save(employee);
        return toMap(employee);
    }

    // ─── Departments ─────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<String> getDepartments() {
        return employeeRepository.findByCompanyCodeAndDepartmentIsNotNullAndIsDeletedFalse(cc())
                .stream()
                .map(Employee::getDepartment)
                .filter(d -> d != null && !d.isBlank())
                .distinct()
                .sorted()
                .collect(Collectors.toList());
    }

    // ─── Stats ───────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public Map<String, Object> getStats() {
        String c = cc();
        long total    = employeeRepository.countByCompanyCodeAndIsDeletedFalse(c);
        long active   = employeeRepository.countByCompanyCodeAndStatusAndIsDeletedFalse(c, "ACTIVE");
        long inactive = employeeRepository.countByCompanyCodeAndStatusAndIsDeletedFalse(c, "INACTIVE");
        long onLeave  = employeeRepository.countByCompanyCodeAndStatusAndIsDeletedFalse(c, "ON_LEAVE");

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalEmployees", total);
        stats.put("activeEmployees", active);
        stats.put("inactiveEmployees", inactive);
        stats.put("onLeaveEmployees", onLeave);
        return stats;
    }

    // ─── Helpers ─────────────────────────────────────────────────────

    private Map<String, Object> toMap(Employee e) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", e.getId());
        map.put("firstName", e.getFirstName());
        map.put("lastName", e.getLastName());
        map.put("fullName", e.getFirstName() + " " + e.getLastName());
        map.put("email", e.getEmail());
        map.put("phone", e.getPhone());
        map.put("department", e.getDepartment());
        map.put("position", e.getPosition());
        map.put("hireDate", e.getHireDate());
        map.put("salary", e.getSalary());
        map.put("status", e.getStatus());
        map.put("nationalId", e.getNationalId());
        map.put("address", e.getAddress());
        map.put("createTime", e.getCreateTime());
        return map;
    }

    private String str(Map<String, Object> data, String key) {
        Object v = data.get(key);
        return v != null ? v.toString() : null;
    }
}
