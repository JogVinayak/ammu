package com.learning.api_gateway.model.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class TokenIntrospectRequest {
    private String token;

}
