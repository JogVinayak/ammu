package com.learning.mindmap_service.model.dto;

import com.learning.mindmap_service.model.enums.PublishScope;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PublishTargets {
    @NotNull
    private PublishScope scope;

    private List<String> classIds;

    private List<String> sectionIds;

    private List<String> userIds;
}
