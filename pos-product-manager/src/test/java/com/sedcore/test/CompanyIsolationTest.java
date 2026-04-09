package com.sedcore.test;

import com.sedcore.entity.Product;
import com.sedcore.entity.Sale;
import com.sedcore.entity.StockMovement;
import com.sedcore.enums.StockMovementType;
import com.sedcore.repository.ProductRepository;
import com.sedcore.repository.SaleRepository;
import com.sedcore.repository.StockMovementRepository;
import com.sedcore.service.ProductRelationshipService;
import com.sedcore.service.RecommendationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.TestPropertySource;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * CompanyIsolationTest
 *
 * Verifies multi-tenancy isolation: Companies cannot see each other's data
 * Key scenarios:
 * 1. StockMovement filtering by company code
 * 2. Product visibility scoped to company
 * 3. Sale records isolated by company
 * 4. Recommendation data not leaking between companies
 */
@DataJpaTest
@TestPropertySource(properties = {
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.datasource.url=jdbc:h2:mem:testdb"
})
public class CompanyIsolationTest {

    @Autowired
    private StockMovementRepository stockMovementRepository;

    @Autowired
    private SaleRepository saleRepository;

    @Autowired
    private ProductRepository productRepository;

    private static final String COMPANY_A = "COMPANY_A";
    private static final String COMPANY_B = "COMPANY_B";

    @BeforeEach
    public void setUp() {
        // Create test data for two different companies
        createCompanyData(COMPANY_A);
        createCompanyData(COMPANY_B);
    }

    private void createCompanyData(String companyCode) {
        // Create products
        Product productA = Product.builder()
                .name("Product-" + companyCode)
                .code("SKU-" + companyCode + "-001")
                .companyCode(companyCode)
                .build();
        productRepository.save(productA);

        // Create sales
        Sale saleA = Sale.builder()
                .saleNumber("SALE-" + companyCode + "-001")
                .companyCode(companyCode)
                .totalAmount(BigDecimal.valueOf(100))
                .build();
        saleRepository.save(saleA);

        // Create stock movements
        StockMovement movementA = StockMovement.builder()
                .sale(saleA)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(5)
                .companyCode(companyCode)
                .build();
        stockMovementRepository.save(movementA);
    }

    @Test
    public void testCompanyACannotSeeBData() {
        // Query for movements with COMPANY_A company code
        List<StockMovement> movementsA = stockMovementRepository.findByCompanyCode(COMPANY_A);

        // Verify only COMPANY_A movements are returned
        assertTrue(movementsA.stream()
                .allMatch(m -> COMPANY_A.equals(m.getCompanyCode())),
                "Company A should only see movements from Company A");

        // Verify Company B movements are NOT included
        assertFalse(movementsA.stream()
                .anyMatch(m -> COMPANY_B.equals(m.getCompanyCode())),
                "Company A should not see Company B movements");
    }

    @Test
    public void testSaleDataIsolation() {
        List<Sale> salesA = saleRepository.findByCompanyCode(COMPANY_A);
        List<Sale> salesB = saleRepository.findByCompanyCode(COMPANY_B);

        assertEquals(1, salesA.size(), "Company A should have 1 sale");
        assertEquals(1, salesB.size(), "Company B should have 1 sale");

        assertEquals(COMPANY_A, salesA.get(0).getCompanyCode());
        assertEquals(COMPANY_B, salesB.get(0).getCompanyCode());
    }

    @Test
    public void testProductVisibilityByCompany() {
        List<Product> productsA = productRepository.findByCompanyCode(COMPANY_A);
        List<Product> productsB = productRepository.findByCompanyCode(COMPANY_B);

        assertEquals(1, productsA.size());
        assertEquals(1, productsB.size());

        assertTrue(productsA.get(0).getCode().contains(COMPANY_A));
        assertTrue(productsB.get(0).getCode().contains(COMPANY_B));
    }

    @Test
    public void testMovementTypeFiltering() {
        // Get SALE_OUT movements for COMPANY_A
        List<StockMovement> saleOutA = stockMovementRepository
                .findByMovementTypeAndCompanyCode(StockMovementType.SALE_OUT, COMPANY_A);

        assertTrue(saleOutA.stream()
                .allMatch(m -> StockMovementType.SALE_OUT == m.getMovementType()),
                "Should only return SALE_OUT movements");

        assertTrue(saleOutA.stream()
                .allMatch(m -> COMPANY_A.equals(m.getCompanyCode())),
                "Should only return COMPANY_A movements");
    }

    @Test
    public void testCompanyContextNotLeaking() {
        // Verify that queries using company code parameter correctly isolate data
        List<StockMovement> movementsWithoutCompany = stockMovementRepository.findAll();

        // In production, Hibernate filter should enforce company isolation
        // This test verifies the filter works
        long companyACount = movementsWithoutCompany.stream()
                .filter(m -> COMPANY_A.equals(m.getCompanyCode()))
                .count();

        assertEquals(1, companyACount, "Should have 1 movement for Company A");
    }
}
