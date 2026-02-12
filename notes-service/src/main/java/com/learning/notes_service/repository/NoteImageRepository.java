package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.NoteImage;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoteImageRepository extends JpaRepository<NoteImage, UUID> {

    List<NoteImage> findByTenantIdAndNoteIdOrderByCreatedAtDesc(UUID tenantId, UUID noteId);

    Optional<NoteImage> findByIdAndTenantId(UUID id, UUID tenantId);
}
