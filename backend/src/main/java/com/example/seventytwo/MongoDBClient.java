package com.example.seventytwo;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.AggregationResults;
import org.springframework.data.mongodb.core.aggregation.MatchOperation;
import org.springframework.data.mongodb.core.aggregation.ProjectionOperation;
import org.springframework.data.mongodb.core.aggregation.SortOperation;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import static org.springframework.data.mongodb.core.query.Criteria.where;

import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import org.bson.Document;

import com.mongodb.BasicDBObject;
import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;

import java.util.ArrayList;
import java.util.List;

@Configuration
public class MongoDBClient {

  // insert your CONNECTION STRING below
  private static final String CONNECTION_STRING = "mongodb+srv://<username>:<password>@<clustername>.abcdef.mongodb.net/<dbname>";
  MongoClient mongoClient;
  MongoTemplate mongoTemplate;

  public String saveAssessment(String assessment, String userID) {
    Document doc = new Document()
        .append("UserID", userID)
        .append("assessment", assessment);
    mongoTemplate.getCollection("assessments").insertOne(doc);
    System.out.println("assessment saved successfully");
    System.out.println(System.out.format("Assesment ID: %s \n", doc.getObjectId("_id")));
    return doc.getObjectId("_id").toString(); // get MongoDB generated ObjectId
  }

  public Document findAssessment(String id) {
    Query query = new Query(where("_id").is(id));
    Document doc = mongoTemplate.findOne(query, Document.class, "assessments");
    if (doc == null) {
      return new Document("error", "Document not found.");
    }
    Object assessment = doc.get("assessment");
    return Document.parse(assessment.toString());
  }

  public Document getAggregatedAssessments(String userId) {
    if (userId == null || userId.isEmpty()) {
      throw new IllegalArgumentException("userId is required");
    }

    List<Document> rawDocs = mongoTemplate.find(
        Query.query(Criteria.where("UserID").is(userId)),
        Document.class,
        "assessments");

    if (rawDocs.isEmpty()) {
      return new Document("error", "No assessments found for user");
    }

    List<Document> assessments = new ArrayList<>();
    double totalPron = 0, totalFluency = 0, totalAccuracy = 0, totalCompleteness = 0;
    int count = 0;

    for (Document raw : rawDocs) {
      String assessmentJson = raw.getString("assessment");
      Document parsed = Document.parse(assessmentJson);

      List<?> nbest = parsed.getList("NBest", Object.class);
      if (nbest == null || nbest.isEmpty()) {
        continue; // or handle missing NBest
      }

      Object first = nbest.get(0);
      if (!(first instanceof Document)) {
        first = Document.parse(first.toString()); // force parse if it's a Map/JSON string
      }
      Document firstDoc = (Document) first;

      Document pron = firstDoc.get("PronunciationAssessment", Document.class);
      if (pron == null) {
        continue; // skip if missing
      }

      double pronScore = pron.getDouble("PronScore");
      double fluency = pron.getDouble("FluencyScore");
      double accuracy = pron.getDouble("AccuracyScore");
      double completeness = pron.getDouble("CompletenessScore");

      Document assessmentInfo = new Document()
          .append("referenceText", parsed.getString("ReferenceText"))
          .append("pronunciationScore", pronScore)
          .append("fluencyScore", fluency)
          .append("accuracyScore", accuracy)
          .append("completenessScore", completeness)
          .append("date", parsed.get("Offset")); // or actual timestamp if available

      assessments.add(assessmentInfo);

      totalPron += pronScore;
      totalFluency += fluency;
      totalAccuracy += accuracy;
      totalCompleteness += completeness;
      count++;
    }

    return new Document()
        .append("userId", userId)
        .append("totalAssessments", count)
        .append("averagePronunciationScore", totalPron / count)
        .append("averageFluencyScore", totalFluency / count)
        .append("averageAccuracyScore", totalAccuracy / count)
        .append("averageCompletenessScore", totalCompleteness / count)
        .append("assessments", assessments);
  }

  public MongoDBClient() {
    try {
      this.mongoClient = MongoClients.create(
          MongoClientSettings.builder()
              .applyConnectionString(new ConnectionString(CONNECTION_STRING))
              .applyToSocketSettings(builder -> builder.connectTimeout(5, TimeUnit.SECONDS))
              .build());
      MongoDatabase db = mongoClient.getDatabase("assessments");
      Document commandResult = db.runCommand(new Document("ping", 1));
      this.mongoTemplate = new MongoTemplate(mongoClient, "assessments");
      if (commandResult.getDouble("ok") == 1.0) {
        System.out.println("\n\n\n\n");
        System.out.println("sUCCESSFUL CONNECTION TO MongoDB!");
        System.out.println("\n\n\n\n");
      } else {
        System.out.println("⚠️ Ping failed: " + commandResult.toJson());
      }
    } catch (Exception e) {
      System.out.println(e.getLocalizedMessage());
    }
  }
}
