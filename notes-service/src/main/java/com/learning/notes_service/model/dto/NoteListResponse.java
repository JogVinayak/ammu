package com.learning.notes_service.model.dto;

import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class NoteListResponse {
    private List<NoteResponse> items;
    private int page;
    private int size;
    private long total;
}
