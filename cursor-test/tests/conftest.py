"""
Pytest configuration and fixtures for Amogh microservices tests.
"""

import pytest
import requests
from dataclasses import dataclass
from typing import Optional, Dict, Any
import time


@dataclass
class ServiceConfig:
    """Configuration for a microservice."""
    name: str
    port: int
    base_url: str
    health_endpoint: str = "/actuator/health"


@dataclass
class TestUser:
    """Test user configuration."""
    email: str
    password: str
    phone: str
    name: str
    tenant_id: str
    user_id: Optional[str] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None


class ServiceRegistry:
    """Registry of all microservices."""
    
    SERVICES = {
        "role-permission-service": ServiceConfig(
            name="role-permission-service",
            port=8080,
            base_url="http://localhost:8080"
        ),
        "auth-service": ServiceConfig(
            name="auth-service",
            port=8081,
            base_url="http://localhost:8081"
        ),
        "tenant-service": ServiceConfig(
            name="tenant-service",
            port=8082,
            base_url="http://localhost:8082"
        ),
        "user-profile-service": ServiceConfig(
            name="user-profile-service",
            port=8083,
            base_url="http://localhost:8083"
        ),
        "api-gateway": ServiceConfig(
            name="api-gateway",
            port=8084,
            base_url="http://localhost:8084"
        ),
        "content-service": ServiceConfig(
            name="content-service",
            port=8085,
            base_url="http://localhost:8085"
        ),
        "content-workflow-service": ServiceConfig(
            name="content-workflow-service",
            port=8086,
            base_url="http://localhost:8086"
        ),
        "graph-relations-service": ServiceConfig(
            name="graph-relations-service",
            port=8087,
            base_url="http://localhost:8087"
        ),
        "notes-service": ServiceConfig(
            name="notes-service",
            port=8088,
            base_url="http://localhost:8088"
        ),
    }
    
    @classmethod
    def get(cls, name: str) -> ServiceConfig:
        return cls.SERVICES[name]
    
    @classmethod
    def get_base_url(cls, name: str) -> str:
        return cls.SERVICES[name].base_url


# Test data constants
DEFAULT_TENANT_ID = "11111111-1111-1111-1111-111111111111"
DEFAULT_TENANT_KEY = "tenant_default"
TEST_USER_EMAIL = "testuser@example.com"
TEST_USER_PASSWORD = "Password123!"
TEST_USER_PHONE = "+919999999999"
TEST_USER_NAME = "Test User"


@pytest.fixture(scope="session")
def service_registry():
    """Provide access to service registry."""
    return ServiceRegistry


@pytest.fixture(scope="session")
def api_gateway_url():
    """API Gateway base URL."""
    return ServiceRegistry.get_base_url("api-gateway")


@pytest.fixture(scope="session")
def auth_service_url():
    """Auth Service base URL."""
    return ServiceRegistry.get_base_url("auth-service")


@pytest.fixture(scope="session")
def tenant_service_url():
    """Tenant Service base URL."""
    return ServiceRegistry.get_base_url("tenant-service")


@pytest.fixture(scope="session")
def notes_service_url():
    """Notes Service base URL."""
    return ServiceRegistry.get_base_url("notes-service")


@pytest.fixture(scope="session")
def role_permission_service_url():
    """Role Permission Service base URL."""
    return ServiceRegistry.get_base_url("role-permission-service")


@pytest.fixture(scope="session")
def content_service_url():
    """Content Service base URL."""
    return ServiceRegistry.get_base_url("content-service")


@pytest.fixture(scope="session")
def default_tenant_id():
    """Default tenant ID for testing."""
    return DEFAULT_TENANT_ID


@pytest.fixture(scope="session")
def default_tenant_key():
    """Default tenant key for testing."""
    return DEFAULT_TENANT_KEY


@pytest.fixture(scope="function")
def test_user():
    """Create a test user configuration."""
    return TestUser(
        email=TEST_USER_EMAIL,
        password=TEST_USER_PASSWORD,
        phone=TEST_USER_PHONE,
        name=TEST_USER_NAME,
        tenant_id=DEFAULT_TENANT_ID
    )


@pytest.fixture(scope="session")
def http_session():
    """Create a requests session with default settings."""
    session = requests.Session()
    session.headers.update({
        "Content-Type": "application/json",
        "Accept": "application/json"
    })
    return session


def check_service_health(base_url: str, timeout: int = 5) -> bool:
    """Check if a service is healthy."""
    try:
        response = requests.get(
            f"{base_url}/actuator/health",
            timeout=timeout
        )
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


def wait_for_service(base_url: str, max_wait: int = 30, interval: int = 2) -> bool:
    """Wait for a service to become healthy."""
    start_time = time.time()
    while time.time() - start_time < max_wait:
        if check_service_health(base_url):
            return True
        time.sleep(interval)
    return False


@pytest.fixture(scope="session", autouse=True)
def verify_services_running(service_registry):
    """Verify required services are running before tests."""
    required_services = ["api-gateway", "auth-service", "tenant-service"]
    missing_services = []
    
    for service_name in required_services:
        service = service_registry.get(service_name)
        if not check_service_health(service.base_url):
            missing_services.append(service_name)
    
    if missing_services:
        pytest.skip(
            f"Required services not running: {', '.join(missing_services)}. "
            f"Please start the services before running tests."
        )


class APIClient:
    """Helper class for making API calls."""
    
    def __init__(self, base_url: str, session: Optional[requests.Session] = None):
        self.base_url = base_url
        self.session = session or requests.Session()
        self.session.headers.update({
            "Content-Type": "application/json",
            "Accept": "application/json"
        })
    
    def set_auth_token(self, token: str):
        """Set the authorization token."""
        self.session.headers["Authorization"] = f"Bearer {token}"
    
    def clear_auth_token(self):
        """Clear the authorization token."""
        self.session.headers.pop("Authorization", None)
    
    def set_tenant_header(self, tenant_id: str):
        """Set the tenant ID header."""
        self.session.headers["X-Tenant-Id"] = tenant_id
    
    def get(self, endpoint: str, **kwargs) -> requests.Response:
        """Make a GET request."""
        return self.session.get(f"{self.base_url}{endpoint}", **kwargs)
    
    def post(self, endpoint: str, json: Dict = None, **kwargs) -> requests.Response:
        """Make a POST request."""
        return self.session.post(f"{self.base_url}{endpoint}", json=json, **kwargs)
    
    def put(self, endpoint: str, json: Dict = None, **kwargs) -> requests.Response:
        """Make a PUT request."""
        return self.session.put(f"{self.base_url}{endpoint}", json=json, **kwargs)
    
    def delete(self, endpoint: str, **kwargs) -> requests.Response:
        """Make a DELETE request."""
        return self.session.delete(f"{self.base_url}{endpoint}", **kwargs)


@pytest.fixture
def api_client(api_gateway_url, http_session):
    """Create an API client for the API Gateway."""
    return APIClient(api_gateway_url, http_session)


@pytest.fixture
def auth_client(auth_service_url):
    """Create an API client for the Auth Service."""
    return APIClient(auth_service_url)


@pytest.fixture
def tenant_client(tenant_service_url):
    """Create an API client for the Tenant Service."""
    return APIClient(tenant_service_url)


@pytest.fixture
def notes_client(notes_service_url):
    """Create an API client for the Notes Service."""
    return APIClient(notes_service_url)


@pytest.fixture
def rps_client(role_permission_service_url):
    """Create an API client for the Role Permission Service."""
    return APIClient(role_permission_service_url)
