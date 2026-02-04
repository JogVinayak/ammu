CREATE ROLE user_profile_user LOGIN PASSWORD 'user_profile_password';
CREATE DATABASE user_profile OWNER user_profile_user;
GRANT ALL PRIVILEGES ON DATABASE user_profile TO user_profile_user;

CREATE ROLE content_service LOGIN PASSWORD 'content_service';
CREATE DATABASE content_service OWNER content_service;
GRANT ALL PRIVILEGES ON DATABASE content_service TO content_service;

CREATE ROLE content_workflow_service LOGIN PASSWORD 'content_workflow_service';
CREATE DATABASE content_workflow_service OWNER content_workflow_service;
GRANT ALL PRIVILEGES ON DATABASE content_workflow_service TO content_workflow_service;


CREATE ROLE mindmap_user LOGIN PASSWORD 'mindmap_password';
CREATE DATABASE mindmap OWNER mindmap_user;
GRANT ALL PRIVILEGES ON DATABASE mindmap TO mindmap_user;

CREATE ROLE notes_user LOGIN PASSWORD 'notes_password';
CREATE DATABASE notes OWNER notes_user;
GRANT ALL PRIVILEGES ON DATABASE notes TO notes_user;