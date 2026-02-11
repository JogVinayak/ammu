package com.learning.tenant_service.repository;

import com.learning.tenant_service.model.entity.Division;
import com.learning.tenant_service.model.enums.SchoolClassStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DivisionRepository extends JpaRepository<Division, UUID> {
    List<Division> findByClassIdAndStatus(UUID classId, SchoolClassStatus status);

    List<Division> findByClassId(UUID classId);

    Optional<Division> findByIdAndClassId(UUID id, UUID classId);

    boolean existsByClassIdAndName(UUID classId, String name);
}
