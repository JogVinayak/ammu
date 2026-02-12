package com.learning.notes_service.service;

import com.learning.notes_service.model.dto.NoteImageResponse;
import com.learning.notes_service.model.entity.NoteImage;
import java.util.List;
import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface NoteImageService {

    NoteImageResponse upload(UUID tenantId, UUID noteId, UUID createdBy, MultipartFile file);

    NoteImage getImageEntity(UUID tenantId, UUID noteId, UUID imageId);

    List<NoteImageResponse> listByNote(UUID tenantId, UUID noteId);

    void delete(UUID tenantId, UUID noteId, UUID imageId);
}
