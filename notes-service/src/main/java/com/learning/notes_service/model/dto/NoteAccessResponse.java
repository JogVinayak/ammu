package com.learning.notes_service.model.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NoteAccessResponse {
    private boolean canRead;
    private boolean canWrite;
}
