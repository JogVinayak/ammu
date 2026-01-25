package com.learning.content_workflow_service.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class SubmitForReviewRequest {
    @NotEmpty
    private List<@NotBlank @Size(min = 1, max = 200) String> reviewerUserIds;

    @NotNull
    @Min(1)
    private Integer requiredApprovals;

    @Size(max = 2000)
    private String note;
}
