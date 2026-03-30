package com.sedcore;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication(scanBasePackages = {"com.sedcore", "com.towpen.base"})
@EntityScan(basePackages = {"com.towpen.base", "com.sedcore.entity"})
@EnableJpaAuditing
public class PosProductManagerApplication {
    public static void main(String[] args) {
        SpringApplication.run(PosProductManagerApplication.class, args);
    }
}
