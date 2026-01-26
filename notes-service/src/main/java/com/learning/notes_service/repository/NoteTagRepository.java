package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.NoteTag;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

public interface NoteTagRepository extends JpaRepository<NoteTag, UUID> {

    List<NoteTag> findByTenantIdAndNoteId(UUID tenantId, UUID noteId);

    @Modifying
    @Transactional
    void deleteByTenantIdAndNoteId(UUID tenantId, UUID noteId);

    boolean existsByTenantIdAndNoteIdAndTag(UUID tenantId, UUID noteId, String tag);
}
