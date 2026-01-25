package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.NodeType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class UpsertNodeRequest {
    @NotNull
    private NodeType type;

    @NotBlank
    @Size(max = 200)
    private String title;

    @Size(max = 5000)
    private String bodyMarkdown;

    private UUID contentId;

    private UUID contentVersionId;

    private Double posX;

    private Double posY;

    private String metaJson;
}
