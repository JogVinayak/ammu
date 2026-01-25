package com.learning.content_workflow_service.dto;

import com.learning.content_workflow_service.enums.PublishTargetScope;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PublishTargets {
    private PublishTargetScope scope;
    private List<String> classIds;
    private List<String> sectionIds;
    private List<String> gradeIds;
    private List<String> userIds;
}
