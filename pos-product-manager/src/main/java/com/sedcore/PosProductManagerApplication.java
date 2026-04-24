package com.sedcore;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = {"com.sedcore", "com.towpen.base"})
@EntityScan(basePackages = {"com.towpen.base", "com.sedcore"})
@EnableJpaAuditing
@EnableScheduling
public class PosProductManagerApplication {
    public static void main(String[] args) {
        SpringApplication.run(PosProductManagerApplication.class, args);
    }
}
