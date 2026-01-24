package com.learning.content_service.dto;

import com.learning.content_service.enums.VersionBumpKind;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class VersionBumpRequest {
    @NotNull
    private VersionBumpKind kind;
}
