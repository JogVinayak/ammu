package com.learning.user_profile_service.repository;

import com.learning.user_profile_service.model.entity.StudentConceptProgress;
import com.learning.user_profile_service.model.enums.ConceptMasteryState;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentConceptProgressRepository extends JpaRepository<StudentConceptProgress, UUID> {

    Optional<StudentConceptProgress> findByTenantIdAndUserIdAndNoteId(
            UUID tenantId, UUID userId, UUID noteId);

    List<StudentConceptProgress> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<StudentConceptProgress> findByTenantIdAndUserIdAndMasteryState(
            UUID tenantId, UUID userId, ConceptMasteryState masteryState);

    List<StudentConceptProgress> findByTenantIdAndUserIdAndMasteryStateIn(
            UUID tenantId, UUID userId, List<ConceptMasteryState> states);

    long countByTenantIdAndUserIdAndMasteryState(
            UUID tenantId, UUID userId, ConceptMasteryState masteryState);
}
