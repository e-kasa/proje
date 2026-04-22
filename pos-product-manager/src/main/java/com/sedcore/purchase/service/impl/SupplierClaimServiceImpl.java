package com.sedcore.purchase.service.impl;

import com.sedcore.common.enums.ClaimReason;
import com.sedcore.common.enums.ClaimStatus;
import com.sedcore.common.exception.BusinessException;
import com.sedcore.common.exception.NotFoundException;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.purchase.entity.SupplierClaim;
import com.sedcore.purchase.entity.SupplierClaimLine;
import com.sedcore.purchase.model.ClaimLineSpec;
import com.sedcore.purchase.model.ClaimResolveRequest;
import com.sedcore.purchase.model.SupplierClaimLineResponse;
import com.sedcore.purchase.model.SupplierClaimResponse;
import com.sedcore.purchase.repository.PurchaseRepository;
import com.sedcore.purchase.repository.SupplierClaimRepository;
import com.sedcore.purchase.service.SupplierClaimLineService;
import com.sedcore.purchase.service.SupplierClaimService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional
public class SupplierClaimServiceImpl
        extends BaseDbServiceImp<SupplierClaimRepository, SupplierClaim>
        implements SupplierClaimService {

    @Autowired private PurchaseRepository purchaseRepository;
    @Autowired private SupplierClaimLineService claimLineService;

    @Override
    public Class<?> getDTOClassForService() {
        return SupplierClaimResponse.class;
    }

    // ─── OPEN ────────────────────────────────────────────────────────────────

    @Override
    public SupplierClaim openClaim(Purchase purchase, List<ClaimLineSpec> lineSpecs, String notes) {
        if (lineSpecs == null || lineSpecs.isEmpty()) {
            throw new BusinessException("Claim satırları boş olamaz");
        }

        BigDecimal totalAmount = lineSpecs.stream()
                .map(ClaimLineSpec::lineAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        ClaimReason aggregateReason = lineSpecs.stream()
                .map(ClaimLineSpec::reason)
                .distinct()
                .count() == 1 ? lineSpecs.get(0).reason() : ClaimReason.SHORTAGE;

        SupplierClaim claim = SupplierClaim.builder()
                .supplier(purchase.getSupplier())
                .sourcePurchase(purchase)
                .claimAmount(totalAmount)
                .claimReason(aggregateReason)
                .status(ClaimStatus.OPEN)
                .isFullyResolved(false)
                .notes(notes)
                .build();
        SupplierClaim saved = save(claim);

        for (ClaimLineSpec spec : lineSpecs) {
            if (spec.shortageQty() <= 0) continue;
            SupplierClaimLine line = SupplierClaimLine.builder()
                    .claim(saved)
                    .variant(spec.variant())
                    .variantSku(spec.variantSku())
                    .productName(spec.productName())
                    .expectedQty(spec.expectedQty())
                    .receivedQty(spec.receivedQty())
                    .unitPrice(spec.unitPrice())
                    .lineAmount(spec.lineAmount())
                    .reason(spec.reason() != null ? spec.reason() : ClaimReason.SHORTAGE)
                    .notes(spec.lineNote())
                    .resolvedQty(0)
                    .resolvedAmount(BigDecimal.ZERO)
                    .isResolved(false)
                    .build();
            claimLineService.save(line);
        }

        log.info("SupplierClaim açıldı: id={}, purchase={}, tutar={}, satır={}, sebep={}",
                saved.getId(), purchase.getId(), totalAmount, lineSpecs.size(), aggregateReason);
        return saved;
    }

    // ─── RESOLVE ─────────────────────────────────────────────────────────────

    @Override
    public SupplierClaimResponse resolveClaim(String claimId, ClaimResolveRequest request) {
        SupplierClaim claim = findById(claimId)
                .orElseThrow(() -> new NotFoundException("Talep bulunamadı: " + claimId));

        if (claim.getStatus() != ClaimStatus.OPEN) {
            throw new BusinessException("Bu talep zaten kapatılmış: " + claim.getStatus());
        }

        ClaimStatus resolution = request.getResolution();
        if (resolution == null || resolution == ClaimStatus.OPEN) {
            throw new BusinessException("Geçersiz çözüm tipi: " + resolution);
        }
        if (resolution == ClaimStatus.CANCELLED) {
            throw new BusinessException("İptal için cancelClaim() kullanın");
        }

        BigDecimal resolvedAmount = request.getResolvedAmount() != null
                ? request.getResolvedAmount()
                : claim.getClaimAmount();

        if (resolvedAmount.compareTo(claim.getClaimAmount()) > 0) {
            throw new BusinessException(
                    "Kapanış tutarı talep tutarından büyük olamaz: " + resolvedAmount + " > " + claim.getClaimAmount());
        }

        if (resolution == ClaimStatus.RESOLVED_DELIVERY
                && request.getResolvedByPurchaseId() != null) {
            Purchase resolvedBy = purchaseRepository.findById(request.getResolvedByPurchaseId())
                    .orElseThrow(() -> new NotFoundException(
                            "Satın alma bulunamadı: " + request.getResolvedByPurchaseId()));
            claim.setResolvedByPurchase(resolvedBy);
        }

        claim.setStatus(resolution);
        claim.setResolvedAmount(resolvedAmount);
        claim.setResolvedDate(LocalDate.now());
        claim.setCreditNoteNumber(request.getCreditNoteNumber());
        if (request.getNotes() != null) {
            claim.setNotes(request.getNotes());
        }

        List<SupplierClaimLine> lines = claimLineService.findByClaimId(claimId);
        boolean fullyResolved = resolvedAmount.compareTo(claim.getClaimAmount()) == 0;
        for (SupplierClaimLine ln : lines) {
            if (fullyResolved) {
                ln.setResolvedQty(ln.shortageQty());
                ln.setResolvedAmount(ln.getLineAmount());
                ln.setIsResolved(true);
            } else {
                BigDecimal ratio = resolvedAmount.divide(claim.getClaimAmount(), 4, java.math.RoundingMode.HALF_UP);
                BigDecimal lineResolved = ln.getLineAmount().multiply(ratio);
                ln.setResolvedAmount(lineResolved);
                int lineResolvedQty = (int) Math.round(ln.shortageQty() * ratio.doubleValue());
                ln.setResolvedQty(lineResolvedQty);
                ln.setIsResolved(lineResolvedQty >= ln.shortageQty());
            }
            claimLineService.update(ln);
        }
        claim.setIsFullyResolved(fullyResolved);

        SupplierClaim saved = save(claim);
        log.info("SupplierClaim kapatıldı: id={}, resolution={}, tutar={}, tamKapanış={}",
                claimId, resolution, resolvedAmount, fullyResolved);
        return toResponseWithLines(saved);
    }

    @Override
    public SupplierClaimResponse cancelClaim(String claimId, String reason) {
        SupplierClaim claim = findById(claimId)
                .orElseThrow(() -> new NotFoundException("Talep bulunamadı: " + claimId));

        if (claim.getStatus() != ClaimStatus.OPEN) {
            throw new BusinessException("Sadece açık talepler iptal edilebilir: " + claim.getStatus());
        }

        claim.setStatus(ClaimStatus.CANCELLED);
        claim.setResolvedDate(LocalDate.now());
        if (reason != null && !reason.isBlank()) {
            String existing = claim.getNotes();
            claim.setNotes((existing != null ? existing + "\n" : "") + "[CANCEL] " + reason);
        }

        SupplierClaim saved = save(claim);
        log.info("SupplierClaim iptal edildi: id={}, sebep={}", claimId, reason);
        return toResponseWithLines(saved);
    }

    // ─── LIST ────────────────────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<SupplierClaimResponse> listByPurchase(String purchaseId) {
        return dao.findBySourcePurchaseId(purchaseId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<SupplierClaimResponse> listBySupplier(String supplierId, ClaimStatus status) {
        List<SupplierClaim> claims = status != null
                ? dao.findBySupplierIdAndStatus(supplierId, status)
                : dao.findBySupplierId(supplierId);
        return claims.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<SupplierClaimResponse> listClaims(String supplierId, ClaimStatus status) {
        List<SupplierClaim> claims;
        if (supplierId != null && status != null) {
            claims = dao.findBySupplierIdAndStatus(supplierId, status);
        } else if (supplierId != null) {
            claims = dao.findBySupplierId(supplierId);
        } else if (status != null) {
            claims = dao.findByStatus(status);
        } else {
            claims = new ArrayList<>();
            dao.findAll().forEach(claims::add);
        }
        return claims.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public SupplierClaimResponse getDetail(String claimId) {
        SupplierClaim claim = findById(claimId)
                .orElseThrow(() -> new NotFoundException("Talep bulunamadı: " + claimId));
        return toResponseWithLines(claim);
    }

    @Override
    @Transactional(readOnly = true)
    public BigDecimal openClaimTotal(String supplierId) {
        return dao.findBySupplierIdAndStatus(supplierId, ClaimStatus.OPEN).stream()
                .map(SupplierClaim::getClaimAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    // ─── MAPPER ──────────────────────────────────────────────────────────────

    @Override
    public SupplierClaimResponse toResponse(SupplierClaim c) {
        return baseResponseBuilder(c).build();
    }

    @Override
    public SupplierClaimResponse toResponseWithLines(SupplierClaim c) {
        List<SupplierClaimLine> lines = claimLineService.findByClaimId(c.getId());
        List<SupplierClaimLineResponse> lineDtos = lines.stream()
                .map(this::toLineResponse)
                .collect(Collectors.toList());
        return baseResponseBuilder(c).lines(lineDtos).build();
    }

    private SupplierClaimResponse.SupplierClaimResponseBuilder baseResponseBuilder(SupplierClaim c) {
        return SupplierClaimResponse.builder()
                .id(c.getId())
                .supplierId(c.getSupplier() != null ? c.getSupplier().getId() : null)
                .supplierName(c.getSupplier() != null ? c.getSupplier().getName() : null)
                .sourcePurchaseId(c.getSourcePurchase() != null ? c.getSourcePurchase().getId() : null)
                .invoiceNumber(c.getSourcePurchase() != null ? c.getSourcePurchase().getInvoiceNumber() : null)
                .claimAmount(c.getClaimAmount())
                .claimReason(c.getClaimReason())
                .status(c.getStatus())
                .notes(c.getNotes())
                .resolvedByPurchaseId(c.getResolvedByPurchase() != null ? c.getResolvedByPurchase().getId() : null)
                .creditNoteNumber(c.getCreditNoteNumber())
                .resolvedAmount(c.getResolvedAmount())
                .resolvedDate(c.getResolvedDate())
                .resolvedBy(c.getResolvedBy())
                .isFullyResolved(c.getIsFullyResolved())
                .createTime(c.getCreateTime() != null ? c.getCreateTime().toString() : null);
    }

    private SupplierClaimLineResponse toLineResponse(SupplierClaimLine ln) {
        return SupplierClaimLineResponse.builder()
                .id(ln.getId())
                .variantId(ln.getVariant() != null ? ln.getVariant().getId() : null)
                .variantSku(ln.getVariantSku())
                .productName(ln.getProductName())
                .expectedQty(ln.getExpectedQty())
                .receivedQty(ln.getReceivedQty())
                .shortageQty(ln.shortageQty())
                .unitPrice(ln.getUnitPrice())
                .lineAmount(ln.getLineAmount())
                .reason(ln.getReason())
                .notes(ln.getNotes())
                .resolvedQty(ln.getResolvedQty())
                .resolvedAmount(ln.getResolvedAmount())
                .isResolved(ln.getIsResolved())
                .build();
    }
}
