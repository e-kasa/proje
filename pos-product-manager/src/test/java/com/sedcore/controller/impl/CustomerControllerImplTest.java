package com.sedcore.controller.impl;

import com.sedcore.entity.Customer;
import com.sedcore.model.CustomerDto;
import com.sedcore.service.CustomerService;
import com.towpen.base.exceptions.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@DisplayName("CustomerControllerImpl Unit Tests")
class CustomerControllerImplTest {

    @Mock
    private CustomerService customerService;

    private CustomerControllerImpl controller;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        controller = new CustomerControllerImpl(customerService);
    }

    @Test
    @DisplayName("Should list all customers successfully")
    void testList_Success() {
        // Arrange
        List<Customer> mockCustomers = Arrays.asList(
            new Customer(), new Customer()
        );
        when(customerService.getAllCustomers()).thenReturn(mockCustomers));

        // Act
        ResponseEntity<ApiResponse<List<Map<String, Object>>>> response = controller.list();

        // Assert
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getSuccess()).isTrue();
        verify(customerService, times(1)).getAllCustomers();
    }

    @Test
    @DisplayName("Should create customer successfully")
    void testCreate_Success() {
        // Arrange
        CustomerDto dto = new CustomerDto();
        dto.setName("Test Customer");
        dto.setEmail("test@example.com");
        dto.setPhone("5551234567");

        Customer savedCustomer = new Customer();
        savedCustomer.setId("123");
        savedCustomer.setName("Test Customer");

        when(customerService.createCustomer(any())).thenReturn(savedCustomer);

        // Act
        ResponseEntity<ApiResponse<Map<String, Object>>> response = controller.create(dto);

        // Assert
        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getSuccess()).isTrue();
        verify(customerService, times(1)).createCustomer(any());
    }

    @Test
    @DisplayName("Should throw exception on error")
    void testCreate_ThrowsException() {
        // Arrange
        CustomerDto dto = new CustomerDto();
        when(customerService.createCustomer(any()))
            .thenThrow(new RuntimeException("Database error"));

        // Act & Assert
        assertThatThrownBy(() -> controller.create(dto))
            .isInstanceOf(Exception.class);
        verify(customerService, times(1)).createCustomer(any());
    }
}
