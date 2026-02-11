package com.learning.user_profile_service.model.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class RecordReadingSessionRequest {

    @NotNull
    private UUID noteId;
}
