package com.learning.user_profile_service.controller;

import com.learning.user_profile_service.model.dto.ClassStudentDto;
import com.learning.user_profile_service.service.StudentProfileService;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/v1/classes")
public class ClassStudentsController {
    private final StudentProfileService studentProfileService;

    @GetMapping("/{classId}/students")
    public Map<String, Object> getStudentsByClass(
            @RequestHeader("X-Tenant-Id") String tenantId,
            @PathVariable UUID classId) {
        UUID tenantUuid = UUID.fromString(tenantId);
        List<ClassStudentDto> students = studentProfileService.getStudentsByClassId(tenantUuid, classId);
        return Map.of("items", students);
    }
}
