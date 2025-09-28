package com.example.seventytwo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

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

}
