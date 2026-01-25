CREATE TABLE IF NOT EXISTS workflows (
    workflow_id uuid PRIMARY KEY,
    tenant_id varchar(255) NOT NULL,
    content_id varchar(255) NOT NULL,
    content_version_id varchar(255) NOT NULL,
    title_snapshot varchar(200),
    state varchar(32) NOT NULL,
    required_approvals integer,
    created_by varchar(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_updated_by varchar(255),
    last_updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    current_step varchar(255),
    publish_targets_json text,
    lock_version bigint,
    CONSTRAINT uk_workflow_tenant_content_version UNIQUE (tenant_id, content_id, content_version_id)
);

CREATE INDEX IF NOT EXISTS idx_workflow_tenant_content
    ON workflows (tenant_id, content_id);

CREATE INDEX IF NOT EXISTS idx_workflow_tenant_content_version
    ON workflows (tenant_id, content_version_id);

CREATE INDEX IF NOT EXISTS idx_workflow_tenant_state
    ON workflows (tenant_id, state);

CREATE INDEX IF NOT EXISTS idx_workflow_tenant_created_by
    ON workflows (tenant_id, created_by);

CREATE TABLE IF NOT EXISTS review_tasks (
    task_id uuid PRIMARY KEY,
    workflow_id uuid NOT NULL,
    assignee_user_id varchar(255) NOT NULL,
    status varchar(32) NOT NULL,
    comment varchar(2000),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_review_task_workflow
        FOREIGN KEY (workflow_id)
        REFERENCES workflows (workflow_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_review_task_workflow
    ON review_tasks (workflow_id);

CREATE INDEX IF NOT EXISTS idx_review_task_assignee
    ON review_tasks (assignee_user_id);

CREATE TABLE IF NOT EXISTS change_requests (
    change_request_id uuid PRIMARY KEY,
    workflow_id uuid NOT NULL,
    requested_by_user_id varchar(255) NOT NULL,
    summary varchar(200),
    details varchar(4000),
    status varchar(32) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_change_request_workflow
        FOREIGN KEY (workflow_id)
        REFERENCES workflows (workflow_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_change_request_workflow
    ON change_requests (workflow_id);

CREATE INDEX IF NOT EXISTS idx_change_request_requester
    ON change_requests (requested_by_user_id);



