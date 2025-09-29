package com.example.seventytwo;

public class AudioUploadResponse {
  private String status;
  private String message;
  private String id;

  public AudioUploadResponse(String status, String message, String id) {
    this.status = status;
    this.message = message;
    this.id = id;
  }

}
