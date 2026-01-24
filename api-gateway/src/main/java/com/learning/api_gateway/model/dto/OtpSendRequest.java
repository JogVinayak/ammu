package com.learning.api_gateway.model.dto;

import com.learning.api_gateway.model.enums.ChallengeChannel;
import com.learning.api_gateway.model.enums.ChallengePurpose;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class OtpSendRequest {
    private ChallengePurpose purpose;
    private ChallengeChannel channel;
    private String target;
    private UUID tenantId;

}
