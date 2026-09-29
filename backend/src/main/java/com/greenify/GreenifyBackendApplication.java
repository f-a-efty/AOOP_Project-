package com.greenify;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class GreenifyBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(GreenifyBackendApplication.class, args);
    }
}
