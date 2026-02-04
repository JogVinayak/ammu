package com.learning.recall_service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class RecallServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(RecallServiceApplication.class, args);
    }
}
