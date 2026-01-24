package com.learning.content_service.dto;

import com.learning.content_service.enums.ContentStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ContentStatusChangeRequest {
    @NotNull
    private ContentStatus status;
}
