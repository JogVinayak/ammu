package com.learning.content_workflow_service.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class ClassResponse {
    UUID id;
    String name;
    String subject;
    String grade;
    String description;
    Integer studentCount;
    List<StudentDto> students;
    List<ReleasedContentDto> releasedContent;
    Instant createdAt;
    Instant updatedAt;

    @Value
    @Builder
    public static class StudentDto {
        String id;
        String name;
        String email;
        String avatar;
    }

    @Value
    @Builder
    public static class ReleasedContentDto {
        String id;
        String title;
        String type;
        Instant releasedAt;
    }
}
