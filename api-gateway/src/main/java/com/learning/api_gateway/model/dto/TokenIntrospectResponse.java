package com.learning.api_gateway.model.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class TokenIntrospectResponse {
    private boolean active;
    private AccessTokenClaims claims;

}
