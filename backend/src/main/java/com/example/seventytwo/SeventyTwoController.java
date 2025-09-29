package com.example.seventytwo;

import java.util.Map;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.bson.Document;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.seventytwo.storage.FileSystemStorageService;
import com.example.seventytwo.storage.StorageService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.microsoft.cognitiveservices.speech.CancellationDetails;
import com.microsoft.cognitiveservices.speech.CancellationReason;
import com.microsoft.cognitiveservices.speech.PronunciationAssessmentConfig;
import com.microsoft.cognitiveservices.speech.PronunciationAssessmentGradingSystem;
import com.microsoft.cognitiveservices.speech.PronunciationAssessmentGranularity;
import com.microsoft.cognitiveservices.speech.PronunciationAssessmentResult;
import com.microsoft.cognitiveservices.speech.PropertyId;
import com.microsoft.cognitiveservices.speech.ResultReason;
import com.microsoft.cognitiveservices.speech.SpeechConfig;
import com.microsoft.cognitiveservices.speech.SpeechRecognitionResult;
import com.microsoft.cognitiveservices.speech.SpeechRecognizer;
import com.microsoft.cognitiveservices.speech.audio.AudioConfig;

@RestController
public class SeventyTwoController {
  private static MongoDBClient db = new MongoDBClient();

  @GetMapping("/api/result/{id}")
  Document getResult(@PathVariable String id) {
    return db.findAssessment(id);
  }

  @GetMapping("api/assessments/{userId}")
  public ResponseEntity<?> getUserDashboard(@PathVariable String userId) {
    if (userId == null || userId.isEmpty()) {
      return ResponseEntity.badRequest().body(
          Map.of("error", "userId parameter is required"));
    }

    try {
      Document aggregatedData = db.getAggregatedAssessments(userId);
      if (aggregatedData == null) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
            Map.of("error", "No assessments found for userId: " + userId));
      }

      // Include userId in the response
      aggregatedData.put("userId", userId);

      return ResponseEntity.ok(aggregatedData);
    } catch (Exception e) {
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
          Map.of("error", e.getMessage()));
    }
  }

  @PostMapping(value = "/api/assess", produces = "application/json")
  @ResponseBody
  ResponseEntity<Object> assess(
      @RequestParam("file") MultipartFile file,
      @RequestParam("referenceText") String referenceText,
      @RequestParam("uid") String uid,
      RedirectAttributes redirectAttributes) {
    try {
      System.out.println("\n\nENTERED\n\n");
      StorageService storageService = new FileSystemStorageService();
      storageService.store(file);
      String id = pronunciationAssessment(storageService.load(file.getOriginalFilename()).toString(), referenceText,
          uid);
      // return new AudioUploadResponse("success", "File Uploaded", id);
      return ResponseEntity.status(HttpStatus.OK).body(Map.of(
          "status", "success",
          "message", "File uploaded.",
          "id", id));
    } catch (Exception e) {
      System.err.println(System.out.format("ERROR: %s", e.getLocalizedMessage()));
    }
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
        "", ""));

  }

  public String pronunciationAssessment(String fileName, String referenceText, String uid) throws Exception {
    String speechRegion = System.getenv("AZURE_SPEECH_REGION");
    String speechKey = System.getenv("AZURE_SPEECH_KEY");

    if (speechKey == null || speechRegion == null) {
      System.out.println("Speech key must be specified");
    }

    AudioConfig audioConfig = AudioConfig.fromWavFileInput(fileName);
    SpeechConfig speechConfig = SpeechConfig.fromSubscription(speechKey, speechRegion);

    System.out.println(fileName);

    SpeechRecognizer speechRecognizer = new SpeechRecognizer(
        speechConfig,
        audioConfig);
    // (Optional) get the session ID
    speechRecognizer.sessionStarted.addEventListener((s, e) -> {
      System.out.println("SESSION ID: " + e.getSessionId());
    });
    PronunciationAssessmentConfig pronunciationAssessmentConfig = new PronunciationAssessmentConfig(
        referenceText,
        PronunciationAssessmentGradingSystem.HundredMark,
        PronunciationAssessmentGranularity.Phoneme,
        true);
    // pronunciationAssessmentConfig.enableProsodyAssessment();

    pronunciationAssessmentConfig.applyTo(speechRecognizer);
    Future<SpeechRecognitionResult> future = speechRecognizer.recognizeOnceAsync();
    SpeechRecognitionResult speechRecognitionResult = future.get(30, TimeUnit.SECONDS);

    // The pronunciation assessment result as a Speech SDK object

    if (speechRecognitionResult.getReason() == ResultReason.RecognizedSpeech) {
      System.out.println("RECOGNIZED: Text=" + speechRecognitionResult.getText());
      System.out.println("  PRONUNCIATION ASSESSMENT RESULTS:");

      PronunciationAssessmentResult pronunciationResult = PronunciationAssessmentResult
          .fromResult(speechRecognitionResult);
      System.out.println(String.format(
          "    Accuracy score: %f, Prosody score: %f, Pronunciation score: %f, Completeness score : %f, FluencyScore: %f",
          pronunciationResult.getAccuracyScore(), pronunciationResult.getProsodyScore(),
          pronunciationResult.getPronunciationScore(), pronunciationResult.getCompletenessScore(),
          pronunciationResult.getFluencyScore()));
    } else if (speechRecognitionResult.getReason() == ResultReason.NoMatch) {
      System.out.println("NOMATCH: Speech could not be recognized.");
    } else if (speechRecognitionResult.getReason() == ResultReason.Canceled) {
      CancellationDetails cancellation = CancellationDetails.fromResult(speechRecognitionResult);
      System.out.println("CANCELED: Reason=" + cancellation.getReason());

      if (cancellation.getReason() == CancellationReason.Error) {
        System.out.println("CANCELED: ErrorCode=" + cancellation.getErrorCode());
        System.out.println("CANCELED: ErrorDetails=" + cancellation.getErrorDetails());
        System.out.println("CANCELED: Did you update the subscription info?");
      }
    }

    // The pronunciation assessment result as a JSON string
    String result = speechRecognitionResult.getProperties().getProperty(PropertyId.SpeechServiceResponse_JsonResult);

    ObjectMapper mapper = new ObjectMapper();
    ObjectNode node = (ObjectNode) mapper.readTree(result);
    node.put("ReferenceText", referenceText);
    node.put("UserID", uid);
    result = mapper.writeValueAsString(node);

    String assesmentID = db.saveAssessment(result, uid);

    speechRecognizer.close();
    speechConfig.close();
    audioConfig.close();
    pronunciationAssessmentConfig.close();
    speechRecognitionResult.close();
    return assesmentID;
  }

}
