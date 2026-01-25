package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.MindMapVisibility;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateMindMapRequest {
    @NotBlank
    @Size(max = 200)
    private String title;

    @Size(max = 2000)
    private String description;

    @Size(max = 100)
    private String subject;

    @Size(max = 50)
    private String grade;

    private List<@Size(min = 1, max = 50) String> tags;

    private MindMapVisibility visibility;

    private UUID createdBy;
}
