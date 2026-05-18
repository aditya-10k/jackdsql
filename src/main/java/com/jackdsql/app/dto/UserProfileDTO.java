package com.jackdsql.app.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserProfileDTO {
    private String id;
    private String email;
    private String name;
    private String profilePicture;
}
