package com.example.ailanguagebuddy.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Loads the 30 predefined topics from topics.json and provides topic context for the AI prompt.
 */
@Component
public class TopicConfigService {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private List<TopicEntry> topics = List.of();

    @PostConstruct
    public void loadTopics() {
        try (InputStream is = new ClassPathResource("topics.json").getInputStream()) {
            JsonNode root = objectMapper.readTree(is);
            JsonNode arr = root.path("topics");
            List<TopicEntry> list = new ArrayList<>();
            for (JsonNode node : arr) {
                list.add(new TopicEntry(
                        node.path("id").asText(),
                        node.path("title").asText(),
                        node.path("instruction").asText(),
                        node.has("languageCode") ? node.path("languageCode").asText("en") : "en"));
            }
            this.topics = List.copyOf(list);
        } catch (Exception e) {
            throw new RuntimeException("Failed to load topics.json", e);
        }
    }

    public Optional<TopicEntry> getTopic(String topicId) {
        if (topicId == null || topicId.isBlank()) {
            return Optional.of(topics.stream().filter(t -> "general".equals(t.id())).findFirst().orElse(topics.get(0)));
        }
        return topics.stream().filter(t -> t.id().equalsIgnoreCase(topicId)).findFirst();
    }

    /** All topic IDs for context in the prompt. */
    public List<String> getAllTopicIds() {
        return topics.stream().map(TopicEntry::id).toList();
    }

    /** Human-readable list of topics for the system prompt. */
    public String getTopicsContextBlock() {
        StringBuilder sb = new StringBuilder();
        for (TopicEntry t : topics) {
            sb.append("- ").append(t.id()).append(": ").append(t.title()).append("\n");
        }
        return sb.toString();
    }

    public record TopicEntry(String id, String title, String instruction, String languageCode) {
        public TopicEntry(String id, String title, String instruction) {
            this(id, title, instruction, "en");
        }
    }
}
