package com.sedcore.test;

import com.sedcore.entity.*;
import com.sedcore.enums.StockMovementType;
import com.sedcore.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.TestPropertySource;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * StockMovementTest
 *
 * Tests stock movement operations: creation, filtering, and tracking
 * Key scenarios:
 * 1. SALE_OUT movement creation and retrieval
 * 2. Movement filtering by variant and store
 * 3. Movement history tracking
 * 4. Frequently bought together analysis
 */
@DataJpaTest
@TestPropertySource(properties = {
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.datasource.url=jdbc:h2:mem:testdb"
})
public class StockMovementTest {

    @Autowired
    private StockMovementRepository stockMovementRepository;

    @Autowired
    private SaleRepository saleRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ProductVariantRepository variantRepository;

    private Sale testSale;
    private ProductVariant testVariant;
    private static final String TEST_COMPANY = "TEST_COMPANY";
    private static final String TEST_STORE = "STORE_001";

    @BeforeEach
    public void setUp() {
        // Create product
        Product product = Product.builder()
                .name("Test Product")
                .code("TEST-001")
                .companyCode(TEST_COMPANY)
                .build();
        productRepository.save(product);

        // Create variant
        testVariant = ProductVariant.builder()
                .product(product)
                .name("Test Variant")
                .sku("VAR-001")
                .companyCode(TEST_COMPANY)
                .build();
        variantRepository.save(testVariant);

        // Create sale
        testSale = Sale.builder()
                .saleNumber("SALE-001")
                .companyCode(TEST_COMPANY)
                .totalAmount(BigDecimal.valueOf(100))
                .saleDate(LocalDateTime.now())
                .build();
        saleRepository.save(testSale);
    }

    @Test
    public void testSaleOutMovementCreation() {
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(5)
                .unitPrice(BigDecimal.valueOf(20))
                .storeId(TEST_STORE)
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement saved = stockMovementRepository.save(movement);

        assertNotNull(saved.getId());
        assertEquals(StockMovementType.SALE_OUT, saved.getMovementType());
        assertEquals(5, saved.getQuantity());
        assertEquals(TEST_COMPANY, saved.getCompanyCode());
    }

    @Test
    public void testMovementRetrievalBySale() {
        // Create multiple movements for same sale
        StockMovement mov1 = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(3)
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement mov2 = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(2)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(mov1);
        stockMovementRepository.save(mov2);

        List<StockMovement> movements = stockMovementRepository
                .findBySaleId(testSale.getId(), TEST_COMPANY);

        assertEquals(2, movements.size());
        assertTrue(movements.stream().allMatch(m -> testSale.getId().equals(m.getSale().getId())));
    }

    @Test
    public void testMovementRetrievalByVariant() {
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(5)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(movement);

        List<StockMovement> retrieved = stockMovementRepository
                .findByVariantId(testVariant.getId(), TEST_COMPANY);

        assertEquals(1, retrieved.size());
        assertEquals(testVariant.getId(), retrieved.get(0).getVariant().getId());
    }

    @Test
    public void testMovementTypeTracking() {
        // Create SALE_OUT movement
        StockMovement saleOut = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(5)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(saleOut);

        // Verify SALE_OUT is recorded correctly
        List<StockMovement> saleOuts = stockMovementRepository.findByMovementTypeAndCompanyCode(
                StockMovementType.SALE_OUT, TEST_COMPANY);

        assertTrue(saleOuts.size() > 0);
        assertTrue(saleOuts.stream().allMatch(m -> StockMovementType.SALE_OUT == m.getMovementType()));
    }

    @Test
    public void testMovementByStoreAndVariant() {
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(5)
                .storeId(TEST_STORE)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(movement);

        List<StockMovement> retrieved = stockMovementRepository
                .findByVariantIdAndStoreId(testVariant.getId(), TEST_STORE, TEST_COMPANY);

        assertEquals(1, retrieved.size());
        assertEquals(TEST_STORE, retrieved.get(0).getStoreId());
    }

    @Test
    public void testMovementHistoryOrdering() {
        // Create movements at different times
        StockMovement mov1 = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(1)
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement mov2 = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(2)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(mov1);
        try {
            Thread.sleep(100); // Small delay to ensure different timestamps
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        stockMovementRepository.save(mov2);

        List<StockMovement> movements = stockMovementRepository
                .findByVariantId(testVariant.getId(), TEST_COMPANY);

        // Should be ordered by createTime DESC (most recent first)
        assertEquals(2, movements.size());
        assertEquals(2, movements.get(0).getQuantity()); // Most recent first
    }

    @Test
    public void testCompanyCodeIsolationInMovements() {
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(5)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(movement);

        // Try to retrieve with different company code
        List<StockMovement> wrongCompany = stockMovementRepository
                .findByVariantId(testVariant.getId(), "WRONG_COMPANY");

        assertTrue(wrongCompany.isEmpty(), "Should not retrieve movements from other companies");
    }
}
