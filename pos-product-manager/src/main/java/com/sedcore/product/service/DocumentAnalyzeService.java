package com.sedcore.product.service;

import com.sedcore.product.model.DocumentAnalyzeResponse;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

public interface DocumentAnalyzeService {

    /**
     * Yüklenen PDF fatura/irsaliye belgesini analiz eder.
     * Her satırı parse eder, sistemdeki ürünlerle eşleştirir.
     */
    DocumentAnalyzeResponse analyze(MultipartFile file) throws IOException;
}
