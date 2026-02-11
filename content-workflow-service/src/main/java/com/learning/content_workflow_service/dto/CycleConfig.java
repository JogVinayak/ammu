package com.learning.content_workflow_service.dto;

import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CycleConfig {

    private List<Integer> intervalDays;

    private Boolean autoRemind;

    private Integer reminderHoursBefore;
}
