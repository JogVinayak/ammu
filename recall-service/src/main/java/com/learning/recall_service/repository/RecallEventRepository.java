package com.learning.recall_service.repository;

import com.learning.recall_service.entity.RecallEvent;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecallEventRepository extends JpaRepository<RecallEvent, UUID> {}
