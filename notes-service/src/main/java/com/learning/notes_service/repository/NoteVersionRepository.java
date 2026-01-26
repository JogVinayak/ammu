package com.learning.notes_service.repository;

import com.learning.notes_service.model.entity.NoteVersion;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NoteVersionRepository extends JpaRepository<NoteVersion, UUID> {

    Optional<NoteVersion> findByIdAndTenantId(UUID id, UUID tenantId);

    List<NoteVersion> findByTenantIdAndNoteIdOrderByVersionNoDesc(UUID tenantId, UUID noteId);

    Optional<NoteVersion> findByTenantIdAndNoteIdAndVersionNo(UUID tenantId, UUID noteId, Integer versionNo);

    @Query("SELECT COALESCE(MAX(v.versionNo), 0) FROM NoteVersion v WHERE v.tenantId = :tenantId AND v.noteId = :noteId")
    Integer findMaxVersionNo(@Param("tenantId") UUID tenantId, @Param("noteId") UUID noteId);

    Optional<NoteVersion> findFirstByTenantIdAndNoteIdOrderByVersionNoDesc(UUID tenantId, UUID noteId);
}
