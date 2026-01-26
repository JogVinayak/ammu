package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.Note;
import com.learning.notes_service.model.enums.NoteScopeType;
import com.learning.notes_service.model.enums.NoteStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface NoteRepository extends JpaRepository<Note, UUID>, JpaSpecificationExecutor<Note> {

    Optional<Note> findByIdAndTenantIdAndDeletedFalse(UUID id, UUID tenantId);

    Page<Note> findByTenantIdAndDeletedFalse(UUID tenantId, Pageable pageable);

    Page<Note> findByTenantIdAndStatusAndDeletedFalse(UUID tenantId, NoteStatus status, Pageable pageable);

    Page<Note> findByTenantIdAndCreatedByAndDeletedFalse(UUID tenantId, UUID createdBy, Pageable pageable);

    Page<Note> findByTenantIdAndScopeTypeAndDeletedFalse(UUID tenantId, NoteScopeType scopeType, Pageable pageable);

    Page<Note> findByTenantIdAndScopeTypeAndScopeIdAndDeletedFalse(
            UUID tenantId, NoteScopeType scopeType, UUID scopeId, Pageable pageable);

    List<Note> findByTenantIdAndDeletedFalse(UUID tenantId);
}
