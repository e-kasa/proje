package com.sedcore.security.controllers.Impl;

import com.sedcore.security.repos.ExtBundleRepository;
import com.sedcore.security.repos.ExtMessageRepository;
import com.towpen.base.restservice.model.RestRootEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Frontend (Flutter/React) icin tum mesaj ve bundle'lari donen public API.
 * Sayfa ilk acildiginda cagrilir ve client-side cache'lenir.
 *
 * GET /api/v1/i18n/all?lang=TR → { messages: {code: text}, bundles: {code: text} }
 */
@RestController
@RequestMapping("/i18n")
@RequiredArgsConstructor
public class RestMessageControllerImpl {

    private final ExtMessageRepository messageRepository;
    private final ExtBundleRepository bundleRepository;

    @GetMapping("/all")
    public RestRootEntity<Map<String, Object>> getAllTranslations(
            @RequestParam(defaultValue = "TR") String lang) {

        boolean isTr = "TR".equalsIgnoreCase(lang);

        // Mesajlar: code → text
        Map<String, String> messages = new HashMap<>();
        messageRepository.findAllMessages().forEach(m ->
                messages.put(m.getMessageCode(), isTr ? m.getMessageTr() : m.getMessageEn()));

        // Bundle'lar: code → text
        Map<String, String> bundles = new HashMap<>();
        bundleRepository.findAllBundles().forEach(b ->
                bundles.put(b.getBundleCode(), isTr ? b.getBundleMessageTr() : b.getBundleMessageEn()));

        Map<String, Object> result = new HashMap<>();
        result.put("lang", isTr ? "TR" : "EN");
        result.put("messages", messages);
        result.put("bundles", bundles);

        return RestRootEntity.ok(result);
    }
}
