package com.example.seventytwo;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import com.example.seventytwo.storage.StorageService;

@SpringBootApplication
public class SeventyTwoApplication {

  public static void main(String[] args) {
    SpringApplication.run(SeventyTwoApplication.class, args);
  }

  @Bean
  CommandLineRunner init(StorageService storageService) {
    return (args) -> {
      storageService.deleteAll();
      storageService.init();
    };
  }
}
