package com.learning.notes_service.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.stereotype.Component;

/**
 * Parses markdown content into a structured JSON format for guided reading.
 * The output contains paragraphs with words and their global indices for
 * word-by-word highlighting in the client.
 */
@Component
public class GuidedReadingParser {

    private static final Pattern PARAGRAPH_SPLIT = Pattern.compile("\\n\\s*\\n|\\n(?=[#\\-*\\d])");
    private static final Pattern HEADING_PREFIX = Pattern.compile("^#{1,6}\\s*");
    private static final Pattern WHITESPACE = Pattern.compile("\\s+");

    // Patterns for stripping markdown from words
    private static final Pattern BOLD_ASTERISK = Pattern.compile("\\*\\*(.+?)\\*\\*");
    private static final Pattern BOLD_UNDERSCORE = Pattern.compile("__(.+?)__");
    private static final Pattern ITALIC_ASTERISK = Pattern.compile("\\*(.+?)\\*");
    private static final Pattern ITALIC_UNDERSCORE = Pattern.compile("_(.+?)_");
    private static final Pattern INLINE_CODE = Pattern.compile("`(.+?)`");
    private static final Pattern LINK = Pattern.compile("\\[(.+?)\\]\\(.+?\\)");
    private static final Pattern LIST_MARKER = Pattern.compile("^[-*+]\\s*");
    private static final Pattern NUMBERED_LIST = Pattern.compile("^\\d+\\.\\s*");

    private final ObjectMapper objectMapper;

    public GuidedReadingParser(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * Parse markdown content into guided reading JSON format.
     *
     * @param markdown The raw markdown content
     * @return JSON string containing paragraphs with words and indices
     */
    public String parse(String markdown) {
        if (markdown == null || markdown.isBlank()) {
            return createEmptyResult();
        }

        GuidedReadingContent content = new GuidedReadingContent();
        List<Paragraph> paragraphs = new ArrayList<>();
        int globalIndex = 0;

        String[] paragraphTexts = PARAGRAPH_SPLIT.split(markdown);

        for (String paragraphText : paragraphTexts) {
            String trimmed = paragraphText.trim();
            if (trimmed.isEmpty()) {
                continue;
            }

            // Detect paragraph type
            boolean isHeading = trimmed.startsWith("#");
            boolean isList = trimmed.startsWith("-") || trimmed.startsWith("*") || trimmed.startsWith("+")
                    || trimmed.matches("^\\d+\\.\\s.*");

            // Clean the text
            String cleanText = trimmed;
            cleanText = HEADING_PREFIX.matcher(cleanText).replaceFirst("");
            cleanText = LIST_MARKER.matcher(cleanText).replaceFirst("");
            cleanText = NUMBERED_LIST.matcher(cleanText).replaceFirst("");
            cleanText = stripInlineMarkdown(cleanText);

            String[] wordArray = WHITESPACE.split(cleanText);
            List<String> words = new ArrayList<>();
            int startIndex = globalIndex;

            for (String word : wordArray) {
                String cleanWord = stripInlineMarkdown(word);
                if (!cleanWord.isEmpty()) {
                    words.add(cleanWord);
                    globalIndex++;
                }
            }

            if (!words.isEmpty()) {
                Paragraph paragraph = new Paragraph();
                paragraph.setText(cleanText);
                paragraph.setHeading(isHeading);
                paragraph.setList(isList);
                paragraph.setWords(words);
                paragraph.setStartWordIndex(startIndex);
                paragraph.setEndWordIndex(globalIndex);
                paragraphs.add(paragraph);
            }
        }

        content.setTotalWords(globalIndex);
        content.setParagraphs(paragraphs);

        try {
            return objectMapper.writeValueAsString(content);
        } catch (JsonProcessingException e) {
            return createEmptyResult();
        }
    }

    /**
     * Strip inline markdown formatting from text.
     */
    private String stripInlineMarkdown(String text) {
        String result = text;
        result = BOLD_ASTERISK.matcher(result).replaceAll("$1");
        result = BOLD_UNDERSCORE.matcher(result).replaceAll("$1");
        result = ITALIC_ASTERISK.matcher(result).replaceAll("$1");
        result = ITALIC_UNDERSCORE.matcher(result).replaceAll("$1");
        result = INLINE_CODE.matcher(result).replaceAll("$1");
        result = LINK.matcher(result).replaceAll("$1");
        // Remove any remaining asterisks or underscores at word boundaries
        result = result.replaceAll("^[*_]+|[*_]+$", "");
        return result.trim();
    }

    private String createEmptyResult() {
        return "{\"totalWords\":0,\"paragraphs\":[]}";
    }

    @Getter
    @Setter
    @NoArgsConstructor
    public static class GuidedReadingContent {
        private int totalWords;
        private List<Paragraph> paragraphs;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Paragraph {
        private String text;
        private boolean isHeading;
        private boolean isList;
        private List<String> words;
        private int startWordIndex;
        private int endWordIndex;
    }
}
