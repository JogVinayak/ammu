package com.learning.auth_service.repository;

import com.learning.auth_service.model.entity.UserIdentity;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserIdentityRepository extends JpaRepository<UserIdentity, UUID> {
    Optional<UserIdentity> findByPrimaryEmail(String email);
    Optional<UserIdentity> findByPrimaryPhone(String phone);
    Optional<UserIdentity> findByPrimaryEmailOrPrimaryPhone(String email, String phone);
}
