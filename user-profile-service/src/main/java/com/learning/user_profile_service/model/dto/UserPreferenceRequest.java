package com.learning.user_profile_service.model.dto;

import java.util.Map;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class UserPreferenceRequest {
    private String language;
    private String timezone;
    private Boolean notificationsEnabled;
    private Map<String, Boolean> channels;
    private Map<String, Object> extra;
}
