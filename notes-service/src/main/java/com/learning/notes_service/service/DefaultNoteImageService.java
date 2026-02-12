package com.learning.notes_service.service;

import com.learning.notes_service.exception.BadRequestException;
import com.learning.notes_service.exception.NotFoundException;
import com.learning.notes_service.model.dto.NoteImageResponse;
import com.learning.notes_service.model.entity.NoteImage;
import com.learning.notes_service.repository.NoteImageRepository;
import com.learning.notes_service.repository.NoteRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class DefaultNoteImageService implements NoteImageService {

    private final NoteImageRepository noteImageRepository;
    private final NoteRepository noteRepository;

    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final List<String> ALLOWED_CONTENT_TYPES = List.of(
            "image/jpeg", "image/png", "image/gif", "image/webp");

    @Override
    @Transactional
    public NoteImageResponse upload(UUID tenantId, UUID noteId, UUID createdBy, MultipartFile file) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        if (file.isEmpty()) {
            throw new BadRequestException("File is empty");
        }
        if (file.getSize() > MAX_IMAGE_SIZE) {
            throw new BadRequestException("File size exceeds maximum of 5MB");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new BadRequestException("Unsupported image type. Allowed: JPEG, PNG, GIF, WebP");
        }

        try {
            NoteImage image = new NoteImage();
            image.setId(UUID.randomUUID());
            image.setTenantId(tenantId);
            image.setNoteId(noteId);
            image.setFileName(file.getOriginalFilename() != null ? file.getOriginalFilename() : "photo.jpg");
            image.setContentType(contentType);
            image.setImageData(file.getBytes());
            image.setSizeBytes(file.getSize());
            image.setCreatedBy(createdBy);
            image.setCreatedAt(Instant.now());

            noteImageRepository.save(image);
            return toResponse(image);
        } catch (java.io.IOException e) {
            throw new BadRequestException("Failed to read uploaded file");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public NoteImage getImageEntity(UUID tenantId, UUID noteId, UUID imageId) {
        NoteImage image = noteImageRepository.findByIdAndTenantId(imageId, tenantId)
                .orElseThrow(() -> new NotFoundException("Image not found"));

        if (!image.getNoteId().equals(noteId)) {
            throw new BadRequestException("Image does not belong to this note");
        }
        return image;
    }

    @Override
    @Transactional(readOnly = true)
    public List<NoteImageResponse> listByNote(UUID tenantId, UUID noteId) {
        noteRepository.findByIdAndTenantIdAndDeletedFalse(noteId, tenantId)
                .orElseThrow(() -> new NotFoundException("Note not found"));

        return noteImageRepository.findByTenantIdAndNoteIdOrderByCreatedAtDesc(tenantId, noteId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional
    public void delete(UUID tenantId, UUID noteId, UUID imageId) {
        NoteImage image = noteImageRepository.findByIdAndTenantId(imageId, tenantId)
                .orElseThrow(() -> new NotFoundException("Image not found"));

        if (!image.getNoteId().equals(noteId)) {
            throw new BadRequestException("Image does not belong to this note");
        }
        noteImageRepository.delete(image);
    }

    private NoteImageResponse toResponse(NoteImage image) {
        NoteImageResponse response = new NoteImageResponse();
        response.setId(image.getId());
        response.setNoteId(image.getNoteId());
        response.setFileName(image.getFileName());
        response.setContentType(image.getContentType());
        response.setSizeBytes(image.getSizeBytes());
        response.setImageUrl("/notes/" + image.getNoteId() + "/images/" + image.getId());
        response.setCreatedBy(image.getCreatedBy());
        response.setCreatedAt(image.getCreatedAt());
        return response;
    }
}
