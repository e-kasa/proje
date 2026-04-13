package com.sedcore.product.controller;


import com.sedcore.product.model.DocumentAnalyzeResponse;
import com.towpen.base.exceptions.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "Belge Analizi", description = "Fatura / irsaliye PDF analizi ve ürün eşleştirme")
@RequestMapping("/api/v1/document")
public interface DocumentAnalyzeController {

    @Operation(summary = "PDF fatura/irsaliyeyi analiz et",
               description = "Yüklenen PDF belgesindeki ürün kalemlerini sistemdeki ürünlerle eşleştirir")
    @PostMapping(value = "/analyze", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    ResponseEntity<ApiResponse<DocumentAnalyzeResponse>> analyzeDocument(
            @RequestParam("file") MultipartFile file
    );
}
