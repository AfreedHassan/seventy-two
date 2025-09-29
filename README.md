# Seventy-Two 

**Seventy-Two** is an end-to-end iOS application for assessing English pronunciation. Users can record audio, submit it for analysis using **Azure Cognitive Services**, and view detailed feedback on words, syllables, and phonemes. Users can also track their progress over time via the **History Dashboard**. Authentication is handled via **OAuth sign-in**. The backend is built in **Spring Boot**, storing assessment results in **MongoDB**.

---

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Setup](#setup)

   * [Backend](#backend-setup)
   * [Frontend](#frontend-setup)
4. [API Reference](#api-reference)
5. [Data Models](#data-models)
6. [Frontend UI Flow](#frontend-ui-flow)
7. [Dashboard / History](#dashboard--history)
8. [Contributing](#contributing)
9. [License](#license)

---

## Features

* **OAuth Sign-In**: Secure user authentication.
* **Audio Recording**: Record directly from the device microphone.
* **Pronunciation Assessment**: Uses Azure Speech SDK to analyze pronunciation.
* **Score Metrics**: Accuracy, fluency, completeness, and overall pronunciation.
* **Word & Phoneme Breakdown**: Detailed per-word and per-phoneme scores.
* **History Dashboard**: Visualizes progress over time with charts and past assessments.
* **Color-coded Scoring**: Green/yellow/red indicators for quick feedback.
* **Persistent Storage**: MongoDB stores JSON results keyed by assessment ID.
* **SwiftUI Frontend**: Modern, interactive UI for recording, visualization, and progress tracking.

---

## Architecture

```
iOS App (SwiftUI + OAuth)
      |
      | POST /api/assess  --> Upload WAV
      |
Spring Boot Backend
      |
      | Azure Cognitive Services (Speech SDK)
      | MongoDB (store assessment JSON)
      |
GET /api/assess/{id}  --> Return assessment JSON
GET /api/history/{userId} --> Return historical assessments
      |
iOS App visualizes results and history
```

**Data Flow:**

1. User signs in via **OAuth** → authenticated session established.
2. User records audio → frontend uploads WAV file.
3. Backend calls Azure Speech SDK for pronunciation analysis.
4. Backend stores raw JSON assessment in MongoDB.
5. Frontend fetches assessment JSON and renders results.
6. Frontend fetches historical assessments → renders dashboard charts & past assessments.

---

## Setup

### Backend

**Requirements:**

* Java 17+
* Maven or Gradle
* MongoDB Atlas or local instance
* Azure Speech SDK key & region

**Configuration:**

```env
AZURE_SPEECH_KEY=<your-key>
AZURE_SPEECH_REGION=<your-region>
SPRING_DATA_MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>/<dbname>
SPRING_DATA_MONGODB_DATABASE=<dbname>
```

**Run Backend:**

```bash
./gradlew bootRun
# or
mvn spring-boot:run
```

* Accessible at `http://localhost:8080`.

---

### Frontend (SwiftUI)

**Requirements:**

* Xcode 15+
* iOS 16+ target
* Swift 5.9+

**Configuration:**

* Backend API URL is set in `AssessmentAPI.swift`.
* Ensure `Info.plist` includes microphone permissions:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record audio for pronunciation assessment.</string>
```

* Ensure OAuth redirect URI and client ID are configured according to your provider (Google, Microsoft, etc.).

**Run App:**

1. Open `SeventyTwo.xcodeproj` in Xcode.
2. Build & run on device or simulator.
3. **Sign in via OAuth** → only authenticated users can record or view assessments.
4. Record audio → stop → assessment results automatically fetched.
5. Visit **History Dashboard** to review past assessments and progress charts.

---

## API Reference

### Upload Audio

* **POST** `/api/assess`
* **Request:** `multipart/form-data` (field name: `file`)
* **Requires:** OAuth Bearer token in Authorization header
* **Response:**

```json
{
  "status": "success",
  "message": "File uploaded",
  "id": "<assessmentId>"
}
```

### Get Assessment

* **GET** `/api/assess/{id}`
* **Requires:** OAuth Bearer token
* **Response:** Full JSON with word-level, syllable-level, and phoneme-level scores.

### Get User History

* **GET** `/api/history/{userId}`
* **Requires:** OAuth Bearer token
* **Response:** JSON array of previous assessments with overall scores and timestamps.

---

## Data Models

**Assessment JSON example:**

```json
{
  "Id": "d4e2e9c49b4546bb91a55f0fe26cb7c9",
  "DisplayText": "Seashore Seashells by the seashore.",
  "PronunciationAssessment": {
    "AccuracyScore": 60.0,
    "FluencyScore": 65.0,
    "CompletenessScore": 67.0,
    "PronScore": 62.4
  },
  "Words": [
    {
      "Word": "seashore",
      "PronunciationAssessment": { "AccuracyScore": 68.0 },
      "Syllables": [...],
      "Phonemes": [...]
    }
  ],
  "Date": "2025-09-29T10:15:00Z"
}
```

**SwiftUI mapping:**

* `Assessment` → root JSON
* `Word`, `Syllable`, `Phoneme` → nested arrays
* Codable structs automatically parse JSON for rendering.

---

## Frontend UI Flow

### 1. Sign-In via OAuth

* Users must authenticate before recording or viewing history.
* Example SwiftUI login button:

```swift
Button("Sign in") { authManager.startOAuthLogin() }
```

### 2. Record Audio

```swift
Button("Record") { audioManager.toggleRecordAudio() }
```

* Circle button changes while recording.
* Audio visualizer animates in real time.
* User can also **input a custom phrase** via styled `TextField`.

### 3. Upload & Receive ID

```swift
audioManager.uploadRecording { assessmentID in
    self.assessmentID = assessmentID
}
```

### 4. Fetch & Display Results

* GET request to backend with assessment ID.
* Display:

  * Overall score (accuracy, fluency, completeness, pronunciation)
  * Transcript
  * Word-level breakdown with **color-coded scoring**
  * Expandable word details for syllables and phonemes

---

## Dashboard / History

### Overview

* Users can view **all past assessments** for a given user.
* Charts visualize metrics over time: Pronunciation, Fluency, Accuracy, Completeness.
* Color-coded cards indicate performance at a glance (green/yellow/red).
* OAuth ensures only the authenticated user sees their own history.


---

## Contributing

* Fork the repository.
* Make changes on a separate branch.
* Test backend & frontend separately.
* Create PR with clear description of changes.

---

## License

MIT License. See [LICENSE](LICENSE) file.

