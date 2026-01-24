package com.learning.content_service.dto;

import com.learning.content_service.enums.ContentType;
import com.learning.content_service.enums.ContentVisibility;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CreateContentRequest {
    @NotNull
    private ContentType type;

    @NotBlank
    @Size(min = 3, max = 200)
    private String title;

    @Size(max = 2000)
    private String description;

    private ContentVisibility visibility;

    private UUID topicId;

    private UUID moduleId;

    private List<@Size(min = 1, max = 50) String> tags;
}
