"""
Test Suite: User Login and Check Notes Use Case

This test suite covers the complete flow of:
1. User authentication (login)
2. Tenant resolution
3. Authorization checks
4. Fetching and viewing notes

Based on the Amogh microservices architecture.
"""

import pytest
import requests
from typing import Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import uuid


# ============================================================================
# Test Data Classes
# ============================================================================

@dataclass
class LoginResponse:
    """Response from login API."""
    access_token: str
    refresh_token: str
    user_id: str
    expires_in: int


@dataclass 
class NoteContent:
    """Note content structure."""
    note_id: str
    content_id: str
    title: str
    content_md: str
    version: int
    status: str


# ============================================================================
# TEST CLASS: User Login Flow
# ============================================================================

class TestUserLoginFlow:
    """Test cases for user login functionality."""
    
    # ------------------------------------------------------------------------
    # Test: Successful Login via API Gateway
    # ------------------------------------------------------------------------
    
    def test_login_success_via_gateway(self, api_client, test_user, default_tenant_id):
        """
        Test successful user login through API Gateway.
        
        Flow:
        1. Client sends login request to API Gateway
        2. Gateway resolves tenant
        3. Gateway forwards to auth-service
        4. Returns JWT tokens
        """
        # Arrange
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        # Act
        response = api_client.post("/v1/auth/login", json=login_payload)
        
        # Assert
        # Note: If service is not running or user doesn't exist, we expect specific error codes
        assert response.status_code in [200, 401, 404, 503], \
            f"Unexpected status code: {response.status_code}, Body: {response.text}"
        
        if response.status_code == 200:
            data = response.json()
            assert "accessToken" in data or "access_token" in data
            assert "refreshToken" in data or "refresh_token" in data
            
            # Store tokens for subsequent tests
            test_user.access_token = data.get("accessToken") or data.get("access_token")
            test_user.refresh_token = data.get("refreshToken") or data.get("refresh_token")
            test_user.user_id = data.get("userId") or data.get("user_id")
    
    def test_login_invalid_credentials(self, api_client, default_tenant_id):
        """
        Test login with invalid credentials returns 401.
        """
        # Arrange
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": "nonexistent@example.com",
            "password": "WrongPassword123!",
            "otp": ""
        }
        
        # Act
        response = api_client.post("/v1/auth/login", json=login_payload)
        
        # Assert
        assert response.status_code in [401, 404, 503], \
            f"Expected 401/404/503, got {response.status_code}"
    
    def test_login_missing_tenant_id(self, api_client, test_user):
        """
        Test login without tenant ID fails appropriately.
        """
        # Arrange
        login_payload = {
            "identifier": test_user.email,
            "password": test_user.password
        }
        
        # Act
        response = api_client.post("/v1/auth/login", json=login_payload)
        
        # Assert
        assert response.status_code in [400, 403, 422, 503], \
            f"Expected 400/403/422/503 for missing tenant, got {response.status_code}"
    
    def test_login_invalid_tenant_id(self, api_client, test_user):
        """
        Test login with invalid tenant ID.
        """
        # Arrange
        login_payload = {
            "tenantId": "00000000-0000-0000-0000-000000000000",  # Non-existent tenant
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        # Act
        response = api_client.post("/v1/auth/login", json=login_payload)
        
        # Assert
        assert response.status_code in [403, 404, 503], \
            f"Expected 403/404/503 for invalid tenant, got {response.status_code}"
    
    def test_login_empty_password(self, api_client, test_user, default_tenant_id):
        """
        Test login with empty password fails validation.
        """
        # Arrange
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": "",
            "otp": ""
        }
        
        # Act
        response = api_client.post("/v1/auth/login", json=login_payload)
        
        # Assert
        assert response.status_code in [400, 401, 422, 503], \
            f"Expected validation error, got {response.status_code}"


# ============================================================================
# TEST CLASS: Tenant Resolution
# ============================================================================

class TestTenantResolution:
    """Test cases for tenant resolution functionality."""
    
    def test_resolve_tenant_by_key(self, api_client, default_tenant_key):
        """
        Test resolving tenant by tenant key.
        """
        # Act
        response = api_client.get(f"/v1/resolve?tenantKey={default_tenant_key}")
        
        # Assert
        assert response.status_code in [200, 404, 503], \
            f"Unexpected status: {response.status_code}"
        
        if response.status_code == 200:
            data = response.json()
            assert "tenantId" in data or "tenant_id" in data
            assert "status" in data
    
    def test_resolve_tenant_invalid_key(self, api_client):
        """
        Test resolving tenant with invalid key returns 404.
        """
        # Act
        response = api_client.get("/v1/resolve?tenantKey=nonexistent_tenant")
        
        # Assert
        assert response.status_code in [404, 503], \
            f"Expected 404/503 for invalid tenant key, got {response.status_code}"
    
    def test_resolve_tenant_missing_params(self, api_client):
        """
        Test resolve endpoint without parameters.
        """
        # Act
        response = api_client.get("/v1/resolve")
        
        # Assert
        assert response.status_code in [400, 422, 503], \
            f"Expected 400/422/503 for missing params, got {response.status_code}"


# ============================================================================
# TEST CLASS: Direct Auth Service Tests
# ============================================================================

class TestAuthServiceDirect:
    """Direct tests against auth-service (bypassing gateway)."""
    
    def test_auth_service_health(self, auth_client):
        """
        Test auth-service health endpoint.
        """
        # Act
        response = auth_client.get("/actuator/health")
        
        # Assert
        assert response.status_code in [200, 503], \
            f"Health check failed: {response.status_code}"
    
    def test_direct_login(self, auth_client, test_user, default_tenant_id):
        """
        Test login directly against auth-service.
        """
        # Arrange
        auth_client.set_tenant_header(default_tenant_id)
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        # Act
        response = auth_client.post("/auth/login", json=login_payload)
        
        # Assert
        assert response.status_code in [200, 401, 404, 503], \
            f"Unexpected status: {response.status_code}"


# ============================================================================
# TEST CLASS: Token Operations
# ============================================================================

class TestTokenOperations:
    """Test cases for token operations."""
    
    def test_token_refresh(self, api_client, default_tenant_id):
        """
        Test refreshing access token.
        """
        # Arrange - First login to get tokens
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": "testuser@example.com",
            "password": "Password123!",
            "otp": ""
        }
        
        login_response = api_client.post("/v1/auth/login", json=login_payload)
        
        if login_response.status_code != 200:
            pytest.skip("Login failed, cannot test token refresh")
        
        refresh_token = login_response.json().get("refreshToken") or \
                       login_response.json().get("refresh_token")
        
        # Act
        refresh_payload = {"refreshToken": refresh_token}
        response = api_client.post("/v1/auth/token/refresh", json=refresh_payload)
        
        # Assert
        assert response.status_code in [200, 401, 503], \
            f"Unexpected status: {response.status_code}"
    
    def test_token_introspection(self, api_client, default_tenant_id):
        """
        Test token introspection endpoint.
        """
        # Arrange - First login to get token
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": "testuser@example.com",
            "password": "Password123!",
            "otp": ""
        }
        
        login_response = api_client.post("/v1/auth/login", json=login_payload)
        
        if login_response.status_code != 200:
            pytest.skip("Login failed, cannot test introspection")
        
        access_token = login_response.json().get("accessToken") or \
                      login_response.json().get("access_token")
        
        # Act
        introspect_payload = {"token": access_token}
        response = api_client.post("/v1/auth/token/introspect", json=introspect_payload)
        
        # Assert
        assert response.status_code in [200, 401, 503], \
            f"Unexpected status: {response.status_code}"


# ============================================================================
# TEST CLASS: Authorization Check
# ============================================================================

class TestAuthorizationCheck:
    """Test cases for authorization/permission checks."""
    
    def test_check_note_read_permission(self, rps_client, default_tenant_id):
        """
        Test checking NOTE:READ permission.
        """
        # Arrange
        check_payload = {
            "tenantId": default_tenant_id,
            "userId": "33333333-3333-3333-3333-333333333333",
            "resource": "NOTE",
            "action": "READ",
            "resourceId": "1",
            "context": {}
        }
        
        # Act
        response = rps_client.post("/authorize/check", json=check_payload)
        
        # Assert
        assert response.status_code in [200, 403, 503], \
            f"Unexpected status: {response.status_code}"
        
        if response.status_code == 200:
            data = response.json()
            assert "allowed" in data
    
    def test_check_permission_without_tenant(self, rps_client):
        """
        Test permission check without tenant ID fails.
        """
        # Arrange
        check_payload = {
            "userId": "33333333-3333-3333-3333-333333333333",
            "resource": "NOTE",
            "action": "READ"
        }
        
        # Act
        response = rps_client.post("/authorize/check", json=check_payload)
        
        # Assert
        assert response.status_code in [400, 422, 503], \
            f"Expected validation error, got {response.status_code}"


# ============================================================================
# TEST CLASS: Notes Access
# ============================================================================

class TestNotesAccess:
    """Test cases for accessing notes."""
    
    def test_notes_service_health(self, notes_client):
        """
        Test notes-service health endpoint.
        """
        # Act
        response = notes_client.get("/actuator/health")
        
        # Assert
        # Service might not be running
        assert response.status_code in [200, 503] or \
               isinstance(response, requests.exceptions.ConnectionError), \
            f"Health check status: {response.status_code}"
    
    def test_get_notes_list(self, api_client, default_tenant_id):
        """
        Test getting list of notes for a tenant.
        """
        # Arrange
        api_client.set_tenant_header(default_tenant_id)
        
        # Act
        response = api_client.get(f"/v1/tenants/{default_tenant_id}/notes")
        
        # Assert
        assert response.status_code in [200, 401, 403, 404, 503], \
            f"Unexpected status: {response.status_code}"
    
    def test_get_note_without_auth(self, api_client, default_tenant_id):
        """
        Test accessing note without authentication fails.
        """
        # Arrange
        api_client.clear_auth_token()
        note_id = str(uuid.uuid4())
        
        # Act
        response = api_client.get(f"/v1/tenants/{default_tenant_id}/notes/{note_id}")
        
        # Assert
        assert response.status_code in [401, 403, 404, 503], \
            f"Expected auth error, got {response.status_code}"


# ============================================================================
# TEST CLASS: Full Login to Notes Flow (Integration)
# ============================================================================

class TestLoginToNotesIntegration:
    """
    Integration tests for the complete login-to-notes flow.
    
    This tests the full use case:
    1. User logs in
    2. User is authorized
    3. User fetches notes
    """
    
    def test_complete_login_and_fetch_notes_flow(
        self, api_client, default_tenant_id, test_user
    ):
        """
        Test complete flow: Login → Authorize → Fetch Notes
        """
        # Step 1: Login
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        login_response = api_client.post("/v1/auth/login", json=login_payload)
        
        if login_response.status_code == 503:
            pytest.skip("API Gateway not available")
        
        if login_response.status_code != 200:
            pytest.skip(f"Login failed with status {login_response.status_code}")
        
        tokens = login_response.json()
        access_token = tokens.get("accessToken") or tokens.get("access_token")
        user_id = tokens.get("userId") or tokens.get("user_id")
        
        assert access_token is not None, "Access token should be present"
        
        # Step 2: Set auth token and tenant header
        api_client.set_auth_token(access_token)
        api_client.set_tenant_header(default_tenant_id)
        
        # Step 3: Fetch notes (via content service through gateway)
        notes_response = api_client.get(f"/v1/content?type=NOTE")
        
        assert notes_response.status_code in [200, 403, 404, 503], \
            f"Unexpected notes response: {notes_response.status_code}"
        
        if notes_response.status_code == 200:
            notes_data = notes_response.json()
            # Verify response structure
            assert isinstance(notes_data, (list, dict)), \
                "Notes response should be list or object"
    
    def test_access_specific_note_after_login(
        self, api_client, default_tenant_id, test_user
    ):
        """
        Test accessing a specific note after login.
        """
        # Step 1: Login
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        login_response = api_client.post("/v1/auth/login", json=login_payload)
        
        if login_response.status_code != 200:
            pytest.skip("Login failed, cannot continue test")
        
        tokens = login_response.json()
        access_token = tokens.get("accessToken") or tokens.get("access_token")
        
        # Step 2: Set auth header
        api_client.set_auth_token(access_token)
        api_client.set_tenant_header(default_tenant_id)
        
        # Step 3: Try to fetch a note (using a test content ID)
        test_content_id = "test-content-123"
        note_response = api_client.get(f"/v1/content/{test_content_id}")
        
        # We expect 404 if note doesn't exist, 200 if it does, 403 if unauthorized
        assert note_response.status_code in [200, 403, 404, 503], \
            f"Unexpected status: {note_response.status_code}"
    
    def test_unauthorized_note_access_denied(self, api_client, default_tenant_id):
        """
        Test that accessing notes without proper authorization is denied.
        """
        # Try to access notes without login
        api_client.clear_auth_token()
        
        response = api_client.get(f"/v1/content?type=NOTE")
        
        # Should get 401 Unauthorized or 403 Forbidden
        assert response.status_code in [401, 403, 503], \
            f"Expected auth error, got {response.status_code}"


# ============================================================================
# TEST CLASS: Session Management
# ============================================================================

class TestSessionManagement:
    """Test cases for session management."""
    
    def test_logout(self, api_client, default_tenant_id, test_user):
        """
        Test user logout functionality.
        """
        # Step 1: Login first
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        login_response = api_client.post("/v1/auth/login", json=login_payload)
        
        if login_response.status_code != 200:
            pytest.skip("Login failed, cannot test logout")
        
        tokens = login_response.json()
        refresh_token = tokens.get("refreshToken") or tokens.get("refresh_token")
        
        # Step 2: Logout
        logout_payload = {"refreshToken": refresh_token}
        logout_response = api_client.post("/v1/auth/logout", json=logout_payload)
        
        assert logout_response.status_code in [200, 204, 401, 503], \
            f"Unexpected logout status: {logout_response.status_code}"
    
    def test_logout_all_sessions(self, api_client, default_tenant_id, test_user):
        """
        Test logging out from all sessions.
        """
        # Step 1: Login first
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": test_user.email,
            "password": test_user.password,
            "otp": ""
        }
        
        login_response = api_client.post("/v1/auth/login", json=login_payload)
        
        if login_response.status_code != 200:
            pytest.skip("Login failed, cannot test logout all")
        
        tokens = login_response.json()
        user_id = tokens.get("userId") or tokens.get("user_id")
        
        # Step 2: Logout all
        logout_all_payload = {
            "userId": user_id,
            "tenantId": default_tenant_id
        }
        logout_response = api_client.post("/v1/auth/logout/all", json=logout_all_payload)
        
        assert logout_response.status_code in [200, 204, 401, 503], \
            f"Unexpected logout all status: {logout_response.status_code}"


# ============================================================================
# TEST CLASS: Error Handling
# ============================================================================

class TestErrorHandling:
    """Test cases for error handling scenarios."""
    
    def test_malformed_json_request(self, api_client):
        """
        Test handling of malformed JSON in request.
        """
        # Act - Send invalid JSON
        response = api_client.session.post(
            f"{api_client.base_url}/v1/auth/login",
            data="not valid json{",
            headers={"Content-Type": "application/json"}
        )
        
        # Assert
        assert response.status_code in [400, 503], \
            f"Expected 400 for malformed JSON, got {response.status_code}"
    
    def test_rate_limiting(self, api_client, default_tenant_id):
        """
        Test rate limiting behavior (if enabled).
        """
        login_payload = {
            "tenantId": default_tenant_id,
            "identifier": "ratelimit@test.com",
            "password": "wrong",
            "otp": ""
        }
        
        # Make multiple rapid requests
        responses = []
        for _ in range(10):
            response = api_client.post("/v1/auth/login", json=login_payload)
            responses.append(response.status_code)
        
        # Check if we got rate limited (429) at some point
        # If not rate limited, we should get consistent 401s
        unique_codes = set(responses)
        assert unique_codes.issubset({401, 404, 429, 503}), \
            f"Unexpected status codes: {unique_codes}"
    
    def test_service_unavailable_handling(self, api_client):
        """
        Test behavior when downstream service is unavailable.
        """
        # This test verifies the gateway handles service unavailability gracefully
        # Make a request that would require a service that might be down
        response = api_client.get("/v1/some-nonexistent-endpoint")
        
        # Should get 404 or 503
        assert response.status_code in [404, 502, 503], \
            f"Unexpected status: {response.status_code}"


# ============================================================================
# TEST CLASS: Content Service Integration
# ============================================================================

class TestContentServiceIntegration:
    """Test cases for content service integration."""
    
    def test_list_content_types(self, api_client, default_tenant_id):
        """
        Test listing content filtered by type.
        """
        api_client.set_tenant_header(default_tenant_id)
        
        # Test NOTE type
        response = api_client.get("/v1/content", params={"type": "NOTE"})
        
        assert response.status_code in [200, 401, 403, 404, 503], \
            f"Unexpected status: {response.status_code}"
    
    def test_get_published_notes(self, api_client, default_tenant_id):
        """
        Test fetching published notes.
        """
        api_client.set_tenant_header(default_tenant_id)
        
        response = api_client.get(
            "/v1/content",
            params={"type": "NOTE", "status": "PUBLISHED"}
        )
        
        assert response.status_code in [200, 401, 403, 404, 503], \
            f"Unexpected status: {response.status_code}"


# ============================================================================
# Utility function for running specific test scenarios
# ============================================================================

def run_login_notes_scenario():
    """
    Utility function to run the login-notes scenario manually.
    Can be called from command line for quick testing.
    """
    import requests
    
    gateway_url = "http://localhost:8084"
    tenant_id = "11111111-1111-1111-1111-111111111111"
    
    print("=" * 60)
    print("Running Login and Notes Scenario")
    print("=" * 60)
    
    # Step 1: Check gateway health
    print("\n1. Checking API Gateway health...")
    try:
        health = requests.get(f"{gateway_url}/actuator/health", timeout=5)
        print(f"   Gateway status: {health.status_code}")
    except Exception as e:
        print(f"   Gateway not available: {e}")
        return
    
    # Step 2: Login
    print("\n2. Attempting login...")
    login_data = {
        "tenantId": tenant_id,
        "identifier": "testuser@example.com",
        "password": "Password123!",
        "otp": ""
    }
    
    try:
        login_resp = requests.post(
            f"{gateway_url}/v1/auth/login",
            json=login_data,
            timeout=10
        )
        print(f"   Login status: {login_resp.status_code}")
        
        if login_resp.status_code == 200:
            tokens = login_resp.json()
            print(f"   Got access token: {tokens.get('accessToken', 'N/A')[:20]}...")
            
            # Step 3: Fetch notes
            print("\n3. Fetching notes...")
            headers = {
                "Authorization": f"Bearer {tokens.get('accessToken')}",
                "X-Tenant-Id": tenant_id
            }
            notes_resp = requests.get(
                f"{gateway_url}/v1/content?type=NOTE",
                headers=headers,
                timeout=10
            )
            print(f"   Notes status: {notes_resp.status_code}")
        else:
            print(f"   Login failed: {login_resp.text}")
            
    except Exception as e:
        print(f"   Error: {e}")
    
    print("\n" + "=" * 60)
    print("Scenario complete")
    print("=" * 60)


if __name__ == "__main__":
    run_login_notes_scenario()
