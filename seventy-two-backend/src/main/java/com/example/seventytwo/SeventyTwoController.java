package com.example.seventytwo;

import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.microsoft.cognitiveservices.speech.CancellationDetails;
import com.microsoft.cognitiveservices.speech.CancellationReason;
import com.microsoft.cognitiveservices.speech.PronunciationAssessmentConfig;
import com.microsoft.cognitiveservices.speech.PronunciationAssessmentResult;
import com.microsoft.cognitiveservices.speech.PropertyId;
import com.microsoft.cognitiveservices.speech.ResultReason;
import com.microsoft.cognitiveservices.speech.SpeechConfig;
import com.microsoft.cognitiveservices.speech.SpeechRecognitionResult;
import com.microsoft.cognitiveservices.speech.SpeechRecognizer;
import com.microsoft.cognitiveservices.speech.audio.AudioConfig;

@RestController
public class SeventyTwoController {

  @PostMapping("/api/assess")
  public void assess(@RequestParam(defaultValue = "World") String name) {

  }

  public void pronunciationAssessment(String fileName) throws Exception {
    String speechRegion = System.getenv("AZURE_SPEECH_REGION");
    String speechKey = System.getenv("AZURE_SPEECH_KEY");

    if (speechKey == null || speechRegion == null) {
      System.out.println("Speech key must be specified");
    }

    AudioConfig audioConfig = AudioConfig.fromWavFileInput(fileName);
    SpeechConfig speechConfig = SpeechConfig.fromAuthorizationToken(speechKey, speechRegion);

    SpeechRecognizer speechRecognizer = new SpeechRecognizer(
        speechConfig,
        audioConfig);
    // (Optional) get the session ID
    speechRecognizer.sessionStarted.addEventListener((s, e) -> {
      System.out.println("SESSION ID: " + e.getSessionId());
    });
    PronunciationAssessmentConfig pronunciationAssessmentConfig = new PronunciationAssessmentConfig(null);
    pronunciationAssessmentConfig.applyTo(speechRecognizer);
    Future<SpeechRecognitionResult> future = speechRecognizer.recognizeOnceAsync();
    SpeechRecognitionResult speechRecognitionResult = future.get(30, TimeUnit.SECONDS);

    // The pronunciation assessment result as a Speech SDK object
    p
    // PronunciationAssessmentResult.fromResult(speechRecognitionResult);

    // The pronunciation assessment result as a JSON string
    // String result =
    // speechRecognitionResult.getProperties().getProperty(PropertyId.SpeechServiceResponse_JsonResult);
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

    speechRecognizer.close();
    speechConfig.close();
    audioConfig.close();
    pronunciationAssessmentConfig.close();
    speechRecognitionResult.close();
  }

}
