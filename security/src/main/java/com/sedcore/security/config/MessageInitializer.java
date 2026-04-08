package com.sedcore.security.config;

import com.sedcore.security.repos.ExtBundleRepository;
import com.sedcore.security.repos.ExtMessageRepository;
import com.towpen.base.internalization.TOpenMessageManager;
import com.towpen.base.restservice.model.ext.BundleValue;
import com.towpen.base.restservice.model.ext.MessageValue;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Uygulama basladiginda ext_messages ve ext_bundles tablolarindan
 * mesajlari okuyup TOpenMessageManager'in in-memory map'ine yukler.
 * Bu sayede TOpenException firlatildiginda ?1004? yerine gercek mesaj donulur.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MessageInitializer implements ApplicationRunner {

    private final ExtMessageRepository messageRepository;
    private final ExtBundleRepository bundleRepository;
    private final TOpenMessageManager messageManager;

    @Override
    public void run(ApplicationArguments args) {
        loadMessages();
        loadBundles();
    }

    private void loadMessages() {
        try {
            List<MessageValue> messages = messageRepository.findAllMessages().stream()
                    .map(e -> new MessageValue(e.getMessageCode(), e.getMessageTr(), e.getMessageEn()))
                    .toList();
            messageManager.addAllMessages(messages);
            log.info("Mesaj sistemi yuklendi: {} mesaj", messages.size());
        } catch (Exception e) {
            log.error("Mesaj sistemi yuklenemedi", e);
        }
    }

    private void loadBundles() {
        try {
            List<BundleValue> bundles = bundleRepository.findAllBundles().stream()
                    .map(e -> new BundleValue(e.getBundleCode(), e.getBundleMessageTr(), e.getBundleMessageEn()))
                    .toList();
            messageManager.addAllBundles(bundles);
            log.info("Bundle sistemi yuklendi: {} bundle", bundles.size());
        } catch (Exception e) {
            log.error("Bundle sistemi yuklenemedi", e);
        }
    }
}
