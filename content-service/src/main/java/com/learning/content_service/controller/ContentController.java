package com.learning.content_service.controller;

import com.learning.content_service.dto.ContentListResponse;
import com.learning.content_service.dto.ContentResponse;
import com.learning.content_service.dto.ContentStatusChangeRequest;
import com.learning.content_service.dto.CreateContentRequest;
import com.learning.content_service.dto.UpdateContentRequest;
import com.learning.content_service.dto.VersionBumpRequest;
import com.learning.content_service.dto.VersionBumpResponse;
import com.learning.content_service.enums.ContentStatus;
import com.learning.content_service.enums.ContentType;
import com.learning.content_service.service.ContentService;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/content")
public class ContentController {
    private final ContentService contentService;

    @PostMapping
    public ResponseEntity<ContentResponse> create(@Valid @RequestBody CreateContentRequest request) {
        ContentResponse response = contentService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    public ContentResponse getById(@PathVariable UUID id) {
        return contentService.getById(id);
    }

    @GetMapping
    public ContentListResponse list(
            @RequestParam(required = false) ContentType type,
            @RequestParam(required = false) ContentStatus status,
            @RequestParam(required = false) UUID topicId,
            @RequestParam(required = false) UUID moduleId,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "updatedAt,desc") String sort) {
        return contentService.list(type, status, topicId, moduleId, q, page, size, sort);
    }

    @PatchMapping("/{id}")
    public ContentResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateContentRequest request) {
        return contentService.update(id, request);
    }

    @PostMapping("/{id}/status")
    public ContentResponse changeStatus(
            @PathVariable UUID id, @Valid @RequestBody ContentStatusChangeRequest request) {
        return contentService.changeStatus(id, request);
    }

    @PostMapping("/{id}/versions/bump")
    public VersionBumpResponse bumpVersion(
            @PathVariable UUID id, @Valid @RequestBody VersionBumpRequest request) {
        return contentService.bumpVersion(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        contentService.softDelete(id);
        return ResponseEntity.noContent().build();
    }
}
