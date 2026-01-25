CREATE ROLE user_profile_user LOGIN PASSWORD 'user_profile_password';
CREATE DATABASE user_profile OWNER user_profile_user;
GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;

CREATE ROLE content_service LOGIN PASSWORD 'content_service';
CREATE DATABASE content_service OWNER content_service;
GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;

CREATE ROLE tenant_user LOGIN PASSWORD 'tenant_password';
CREATE DATABASE tenant OWNER tenant_user;
GRANT ALL PRIVILEGES ON DATABASE tenant TO tenant_user;

CREATE ROLE auth_user LOGIN PASSWORD 'auth_password';
CREATE DATABASE auth OWNER auth_user;
GRANT ALL PRIVILEGES ON DATABASE auth TO auth_user;

CREATE ROLE auth_user LOGIN PASSWORD 'auth_password';
CREATE DATABASE auth OWNER auth_user;
GRANT ALL PRIVILEGES ON DATABASE auth TO auth_user;
