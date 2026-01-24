
CREATE ROLE tenant_user LOGIN PASSWORD 'tenant_password';

CREATE DATABASE tenant OWNER tenant_user;

GRANT ALL PRIVILEGES ON DATABASE tenant TO tenant_user;