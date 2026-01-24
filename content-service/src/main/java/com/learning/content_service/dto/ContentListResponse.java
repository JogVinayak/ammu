package com.learning.content_service.dto;

import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class ContentListResponse {
    private List<ContentResponse> items;
    private int page;
    private int size;
    private long total;
}
