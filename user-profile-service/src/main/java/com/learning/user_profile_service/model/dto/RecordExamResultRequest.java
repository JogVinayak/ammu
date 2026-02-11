package com.learning.user_profile_service.model.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class RecordExamResultRequest {

    @NotNull
    private UUID noteId;

    @NotNull
    @Min(0)
    @Max(100)
    private Integer score;

    @NotNull
    private Boolean passed;
}
