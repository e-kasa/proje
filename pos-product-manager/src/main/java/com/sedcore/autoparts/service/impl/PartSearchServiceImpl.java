package com.sedcore.autoparts.service.impl;

import com.sedcore.product.entity.Product;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.product.entity.Barcode;
import com.sedcore.product.entity.Brand;
import com.sedcore.autoparts.entity.CrossReference;
import com.sedcore.autoparts.entity.OemNumber;
import com.sedcore.autoparts.entity.Vehicle;
import com.sedcore.autoparts.entity.VehicleCompatibility;
import com.sedcore.autoparts.model.CrossReferenceResponse;
import com.sedcore.autoparts.model.OemNumberResponse;
import com.sedcore.autoparts.model.PartSearchResponse;
import com.sedcore.product.repository.ProductRepository;
import com.sedcore.autoparts.repository.CrossReferenceRepository;
import com.sedcore.autoparts.repository.OemNumberRepository;
import com.sedcore.autoparts.repository.VehicleCompatibilityRepository;
import com.sedcore.autoparts.service.PartSearchService;
import lombok.RequiredArgsConstructor;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PartSearchServiceImpl implements PartSearchService {

    private final ProductRepository productRepository;
    private final OemNumberRepository oemNumberRepository;
    private final CrossReferenceRepository crossReferenceRepository;
    private final VehicleCompatibilityRepository vehicleCompatibilityRepository;

    @Override
    public List<PartSearchResponse> searchParts(String keyword, String make, String model, Integer year) {
        Set<String> matchedVariantIds = new LinkedHashSet<>();

        // 1. Anahtar kelime ile arama (isim, SKU, OEM, capraz ref)
        if (keyword != null && !keyword.isBlank()) {
            String q = keyword.trim();

            // Urun adi ve SKU ile arama
            List<Product> products = productRepository.searchProducts(q);
            for (Product p : products) {
                if (p.getVariants() != null) {
                    for (ProductVariant v : p.getVariants()) {
                        if (!Boolean.TRUE.equals(v.getIsDeleted())) {
                            matchedVariantIds.add(v.getId());
                        }
                    }
                }
            }

            // OEM numarasi ile arama
            List<OemNumber> oemResults = oemNumberRepository.searchByOemNumber(q);
            for (OemNumber o : oemResults) {
                matchedVariantIds.add(o.getVariant().getId());
            }

            // Capraz referans ile arama
            List<CrossReference> crResults = crossReferenceRepository.searchByCrossRefNumber(q);
            for (CrossReference cr : crResults) {
                matchedVariantIds.add(cr.getVariant().getId());
            }
        }

        // 2. Arac filtresi ile arama
        if (make != null || model != null || year != null) {
            List<VehicleCompatibility> vcResults = vehicleCompatibilityRepository.searchByVehicle(make, model, year);
            Set<String> vehicleMatchedIds = vcResults.stream()
                    .map(vc -> vc.getVariant().getId())
                    .collect(Collectors.toSet());

            if (keyword != null && !keyword.isBlank()) {
                // Hem anahtar kelime hem arac filtresi varsa kesisim al
                matchedVariantIds.retainAll(vehicleMatchedIds);
            } else {
                // Sadece arac filtresi varsa
                matchedVariantIds.addAll(vehicleMatchedIds);
            }
        }

        // Sonuc yoksa bos don
        if (matchedVariantIds.isEmpty()) {
            return Collections.emptyList();
        }

        // 3. Sonuclari zenginlestir
        List<PartSearchResponse> responses = new ArrayList<>();
        for (String variantId : matchedVariantIds) {
            try {
                PartSearchResponse response = buildResponse(variantId);
                if (response != null) {
                    responses.add(response);
                }
            } catch (Exception e) {
                log.warn("Varyant sonucu olusturulurken hata ({}): {}", variantId, e.getMessage());
            }
        }

        return responses;
    }

    private PartSearchResponse buildResponse(String variantId) {
        // Varyant ve urun bilgisi
        // OemNumber uzerinden varyanta ulasabiliyoruz
        List<OemNumber> oems = oemNumberRepository.findByVariantIdOrderByIsPrimaryDesc(variantId);
        List<CrossReference> crossRefs = crossReferenceRepository.findByVariantIdOrderByCrossRefBrandAsc(variantId);
        List<VehicleCompatibility> compatibilities = vehicleCompatibilityRepository.findByVariantId(variantId);

        // Varyant bilgisini OEM veya CrossRef veya Compatibility'den al
        ProductVariant variant = null;
        if (!oems.isEmpty()) {
            variant = oems.get(0).getVariant();
        } else if (!crossRefs.isEmpty()) {
            variant = crossRefs.get(0).getVariant();
        } else if (!compatibilities.isEmpty()) {
            variant = compatibilities.get(0).getVariant();
        }

        if (variant == null) return null;

        Product product = variant.getProduct();

        // Fiyat bilgisi
        java.math.BigDecimal salePrice = null;
        java.math.BigDecimal purchasePrice = null;
        if (variant.getVariantPricings() != null && !variant.getVariantPricings().isEmpty()) {
            VariantPricing pricing = variant.getVariantPricings().get(0);
            salePrice = pricing.getSalePrice();
            purchasePrice = pricing.getPurchasePrice();
        }

        // Barkodlar
        List<String> barcodeList = Collections.emptyList();
        if (variant.getBarcodes() != null) {
            barcodeList = variant.getBarcodes().stream()
                    .map(Barcode::getBarcodeCode)
                    .collect(Collectors.toList());
        }

        return PartSearchResponse.builder()
                .productId(product != null ? product.getId() : null)
                .productName(product != null ? product.getName() : null)
                .variantId(variant.getId())
                .variantSku(variant.getSku())
                .variantName(variant.getName())
                .brand(product != null ? product.getBrand() : null)
                .salePrice(salePrice)
                .purchasePrice(purchasePrice)
                .shelfLocationCode(variant.getShelfLocationCode())
                .minStockLevel(variant.getMinStockLevel())
                .oemNumbers(oems.stream().map(o -> OemNumberResponse.builder()
                        .id(o.getId())
                        .variantId(o.getVariant().getId())
                        .oemNumber(o.getOemNumber())
                        .manufacturer(o.getManufacturer())
                        .isPrimary(o.getIsPrimary())
                        .build()).collect(Collectors.toList()))
                .crossReferences(crossRefs.stream().map(cr -> CrossReferenceResponse.builder()
                        .id(cr.getId())
                        .variantId(cr.getVariant().getId())
                        .crossRefNumber(cr.getCrossRefNumber())
                        .crossRefBrand(cr.getCrossRefBrand())
                        .notes(cr.getNotes())
                        .build()).collect(Collectors.toList()))
                .barcodes(barcodeList)
                .compatibleVehicles(compatibilities.stream().map(vc -> {
                    Vehicle v = vc.getVehicle();
                    return PartSearchResponse.CompatibleVehicleSummary.builder()
                            .vehicleId(v.getId())
                            .make(v.getMake())
                            .model(v.getModel())
                            .yearStart(v.getYearStart())
                            .yearEnd(v.getYearEnd())
                            .build();
                }).collect(Collectors.toList()))
                .build();
    }
}
