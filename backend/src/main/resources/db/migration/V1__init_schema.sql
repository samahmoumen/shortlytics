-- 1. Table users
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255),
    username VARCHAR(255),
    password VARCHAR(255),
    role VARCHAR(255) DEFAULT 'ROLE_USER'
);

-- 2. Table url_mapping
CREATE TABLE IF NOT EXISTS url_mapping (
    id BIGSERIAL PRIMARY KEY,
    original_url VARCHAR(255),
    short_url VARCHAR(255),
    click_count INT NOT NULL DEFAULT 0,
    created_date TIMESTAMP,
    user_id BIGINT,
    CONSTRAINT fk_url_mapping_user FOREIGN KEY (user_id) REFERENCES users (id)
);

-- 3. Table click_event
CREATE TABLE IF NOT EXISTS click_event (
    id BIGSERIAL PRIMARY KEY,
    click_date TIMESTAMP,
    url_mapping_id BIGINT,
    CONSTRAINT fk_click_event_url_mapping FOREIGN KEY (url_mapping_id) REFERENCES url_mapping (id)
);