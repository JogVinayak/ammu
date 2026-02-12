package com.learning.notes_service.controller;

import com.learning.notes_service.model.dto.NoteImageResponse;
import com.learning.notes_service.model.entity.NoteImage;
import com.learning.notes_service.service.NoteImageService;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RequiredArgsConstructor
@RestController
@RequestMapping("/notes/{noteId}/images")
public class NoteImageController {

    private final NoteImageService noteImageService;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<NoteImageResponse> upload(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @RequestParam("file") MultipartFile file,
            @RequestHeader(value = "X-User-Id", required = false) UUID createdBy) {
        NoteImageResponse response = noteImageService.upload(tenantId, noteId, createdBy, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{imageId}")
    public ResponseEntity<byte[]> getImage(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID imageId) {
        NoteImage image = noteImageService.getImageEntity(tenantId, noteId, imageId);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType(image.getContentType()));
        headers.setContentLength(image.getSizeBytes());
        headers.setCacheControl("public, max-age=3600");

        return new ResponseEntity<>(image.getImageData(), headers, HttpStatus.OK);
    }

    @GetMapping
    public List<NoteImageResponse> list(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId) {
        return noteImageService.listByNote(tenantId, noteId);
    }

    @DeleteMapping("/{imageId}")
    public ResponseEntity<Void> delete(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID noteId,
            @PathVariable UUID imageId) {
        noteImageService.delete(tenantId, noteId, imageId);
        return ResponseEntity.noContent().build();
    }
}
