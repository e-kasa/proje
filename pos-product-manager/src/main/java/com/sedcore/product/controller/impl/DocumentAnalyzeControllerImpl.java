package com.sedcore.product.controller.impl;

import com.sedcore.common.exception.BusinessException;
import com.sedcore.product.controller.DocumentAnalyzeController;
import com.sedcore.product.model.DocumentAnalyzeResponse;
import com.sedcore.product.service.DocumentAnalyzeService;
import com.towpen.base.exceptions.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequiredArgsConstructor
@Slf4j
public class DocumentAnalyzeControllerImpl implements DocumentAnalyzeController {

    private final DocumentAnalyzeService documentAnalyzeService;

    @Override
    public ResponseEntity<ApiResponse<DocumentAnalyzeResponse>> analyzeDocument(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("Dosya boş olamaz");
        }

        String fileName = file.getOriginalFilename() != null
                ? file.getOriginalFilename().toLowerCase() : "";
        if (!fileName.endsWith(".pdf") && !isImageFile(fileName)) {
            throw new BusinessException(
                    "Desteklenmeyen dosya formatı. PDF veya görüntü (JPG, PNG, WEBP) yükleyin.");
        }

        try {
            log.info("Belge analizi başlatıldı: {}, boyut: {} bytes", fileName, file.getSize());
            DocumentAnalyzeResponse result = documentAnalyzeService.analyze(file);
            log.info("Belge analizi tamamlandı: {} kalem, {} eşleşme",
                    result.getTotalItems(), result.getFoundItems());
            return ResponseEntity.ok(ApiResponse.success(result));
        } catch (BusinessException e) {
            throw e;
        } catch (IOException e) {
            log.error("Dosya okunamadı: {}", e.getMessage());
            throw new BusinessException("Dosya okunamadı: " + e.getMessage());
        } catch (Exception e) {
            log.error("Belge analiz hatası: {}", e.getMessage(), e);
            throw new BusinessException("Belge analizi sırasında hata oluştu: " + e.getMessage());
        }
    }

    private boolean isImageFile(String fileName) {
        return fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")
                || fileName.endsWith(".png") || fileName.endsWith(".webp")
                || fileName.endsWith(".bmp");
    }
}
