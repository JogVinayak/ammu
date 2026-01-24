package com.learning.content_service.dto;

import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class VersionBumpResponse {
    private UUID contentId;
    private Integer currentVersion;
    private Integer latestDraftVersion;
}
