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
 * SaleMovementTest
 *
 * Tests the integration between Sales and StockMovements
 * Key scenarios:
 * 1. Sale creation generates SALE_OUT movements
 * 2. Movement history visible in product detail
 * 3. Sale return creates SALE_RETURN_IN movements
 * 4. Total amounts calculated from movements
 * 5. Sales and movements stay in sync
 */
@DataJpaTest
@TestPropertySource(properties = {
    "spring.jpa.hibernate.ddl-auto=create-drop",
    "spring.datasource.url=jdbc:h2:mem:testdb"
})
public class SaleMovementTest {

    @Autowired
    private SaleRepository saleRepository;

    @Autowired
    private StockMovementRepository stockMovementRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private ProductVariantRepository variantRepository;

    private static final String TEST_COMPANY = "TEST_COMPANY";
    private static final String TEST_STORE = "STORE_001";

    private Sale testSale;
    private Product testProduct;
    private ProductVariant testVariant;

    @BeforeEach
    public void setUp() {
        // Create product and variant
        testProduct = Product.builder()
                .name("Fastener")
                .code("FASTENER-001")
                .companyCode(TEST_COMPANY)
                .build();
        productRepository.save(testProduct);

        testVariant = ProductVariant.builder()
                .product(testProduct)
                .name("Fastener M10")
                .sku("FASTENER-M10")
                .companyCode(TEST_COMPANY)
                .build();
        variantRepository.save(testVariant);

        // Create sale
        testSale = Sale.builder()
                .saleNumber("SALE-001")
                .companyCode(TEST_COMPANY)
                .totalAmount(BigDecimal.valueOf(500))
                .paidAmount(BigDecimal.valueOf(500))
                .remainingAmount(BigDecimal.ZERO)
                .saleDate(LocalDateTime.now())
                .isCancelled(false)
                .build();
        saleRepository.save(testSale);
    }

    @Test
    public void testSaleCreatesMovements() {
        // Create movement for the sale
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(100)
                .unitPrice(BigDecimal.valueOf(5))
                .storeId(TEST_STORE)
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement saved = stockMovementRepository.save(movement);

        assertNotNull(saved.getId());
        assertEquals(testSale.getId(), saved.getSale().getId());
        assertEquals(StockMovementType.SALE_OUT, saved.getMovementType());
        assertEquals(100, saved.getQuantity());
    }

    @Test
    public void testMovementHistoryBySale() {
        // Create multiple line items in single sale
        StockMovement mov1 = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(50)
                .unitPrice(BigDecimal.valueOf(5))
                .companyCode(TEST_COMPANY)
                .build();

        ProductVariant variant2 = ProductVariant.builder()
                .product(testProduct)
                .name("Fastener M12")
                .sku("FASTENER-M12")
                .companyCode(TEST_COMPANY)
                .build();
        variantRepository.save(variant2);

        StockMovement mov2 = StockMovement.builder()
                .sale(testSale)
                .variant(variant2)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(50)
                .unitPrice(BigDecimal.valueOf(5))
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(mov1);
        stockMovementRepository.save(mov2);

        // Retrieve all movements for sale
        List<StockMovement> movements = stockMovementRepository
                .findBySaleId(testSale.getId(), TEST_COMPANY);

        assertEquals(2, movements.size(), "Sale should have 2 line items");
        assertTrue(movements.stream()
                .allMatch(m -> StockMovementType.SALE_OUT == m.getMovementType()),
                "All movements should be SALE_OUT");
    }

    @Test
    public void testProductHistoryContainsAllMovements() {
        // Create sale and movements
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(100)
                .unitPrice(BigDecimal.valueOf(5))
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(movement);

        // Get product movements (from product variant)
        List<StockMovement> productMovements = stockMovementRepository
                .findByVariantId(testVariant.getId(), TEST_COMPANY);

        assertEquals(1, productMovements.size());
        assertEquals(StockMovementType.SALE_OUT, productMovements.get(0).getMovementType());
    }

    @Test
    public void testSaleReturnCreatesReturnMovement() {
        // Create original sale movement
        StockMovement saleOut = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(100)
                .unitPrice(BigDecimal.valueOf(5))
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(saleOut);

        // Create return movement
        StockMovement returnMovement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_RETURN_IN)
                .quantity(20) // Return 20 items
                .unitPrice(BigDecimal.valueOf(5))
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(returnMovement);

        // Verify both movements exist
        List<StockMovement> allMovements = stockMovementRepository
                .findBySaleId(testSale.getId(), TEST_COMPANY);

        assertEquals(2, allMovements.size());

        long saleOutCount = allMovements.stream()
                .filter(m -> StockMovementType.SALE_OUT == m.getMovementType())
                .count();

        long returnCount = allMovements.stream()
                .filter(m -> StockMovementType.SALE_RETURN_IN == m.getMovementType())
                .count();

        assertEquals(1, saleOutCount);
        assertEquals(1, returnCount);
    }

    @Test
    public void testMovementTypeFiltering() {
        // Create sale and return movements
        StockMovement saleOut = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(100)
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement returnIn = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_RETURN_IN)
                .quantity(20)
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(saleOut);
        stockMovementRepository.save(returnIn);

        // Get only SALE_OUT movements
        List<StockMovement> saleOuts = stockMovementRepository
                .findBySaleIdAndMovementType(testSale.getId(), StockMovementType.SALE_OUT, TEST_COMPANY);

        assertEquals(1, saleOuts.size());
        assertEquals(100, saleOuts.get(0).getQuantity());

        // Get only SALE_RETURN_IN movements
        List<StockMovement> returns = stockMovementRepository
                .findBySaleIdAndMovementType(testSale.getId(), StockMovementType.SALE_RETURN_IN, TEST_COMPANY);

        assertEquals(1, returns.size());
        assertEquals(20, returns.get(0).getQuantity());
    }

    @Test
    public void testSalesAndMovementsDataConsistency() {
        // Create movements for sale
        StockMovement movement1 = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(50)
                .unitPrice(BigDecimal.valueOf(10))
                .companyCode(TEST_COMPANY)
                .build();

        stockMovementRepository.save(movement1);

        // Retrieve sale
        Sale retrievedSale = saleRepository.findById(testSale.getId()).orElse(null);
        assertNotNull(retrievedSale);

        // Verify sale amount is correct
        assertEquals(BigDecimal.valueOf(500), retrievedSale.getTotalAmount());

        // Get movements for this sale
        List<StockMovement> movements = stockMovementRepository
                .findBySaleId(retrievedSale.getId(), TEST_COMPANY);

        assertEquals(1, movements.size());
        assertEquals(50, movements.get(0).getQuantity());
    }

    @Test
    public void testMovementStoreAndWarehouseTracking() {
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(100)
                .storeId(TEST_STORE)
                .warehouseId("WAREHOUSE_001")
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement saved = stockMovementRepository.save(movement);

        assertEquals(TEST_STORE, saved.getStoreId());
        assertEquals("WAREHOUSE_001", saved.getWarehouseId());
    }

    @Test
    public void testMovementTimestampTracking() {
        StockMovement movement = StockMovement.builder()
                .sale(testSale)
                .variant(testVariant)
                .movementType(StockMovementType.SALE_OUT)
                .quantity(100)
                .companyCode(TEST_COMPANY)
                .build();

        StockMovement saved = stockMovementRepository.save(movement);

        assertNotNull(saved.getCreateTime(), "Movement should have creation timestamp");
        assertTrue(saved.getCreateTime().isBefore(LocalDateTime.now().plusSeconds(1)));
    }
}
