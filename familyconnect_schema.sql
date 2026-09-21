-- ================================================================
-- FAMILYCONNECT — SCRIPT CÀI ĐẶT CƠ SỞ DỮ LIỆU (PostgreSQL 16)
-- Đề tài: FamilyConnect — AI-powered Digital Family Community Platform
-- Gồm 4 phần: (1) tạo database, (2) tạo bảng, (3) constraint, (4) index
-- ================================================================

-- ============================================================
-- 1. TẠO DATABASE
-- ============================================================
-- Tạo database cho hệ thống FamilyConnect
CREATE DATABASE familyconnect_db
    WITH ENCODING   = 'UTF8'
         LC_COLLATE = 'en_US.UTF-8'
         LC_CTYPE   = 'en_US.UTF-8'
         TEMPLATE   = template0;

-- Kết nối tới database vừa tạo (psql) trước khi chạy các lệnh tiếp theo
\c familyconnect_db

-- Kích hoạt các extension cần thiết
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- sinh khóa chính dạng UUID (gen_random_uuid)
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- tìm kiếm gần đúng (fuzzy search) theo họ tên

-- ============================================================
-- 2. TẠO BẢNG — Nhóm 1: User & Security
-- ============================================================
CREATE TABLE users (
    user_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name      VARCHAR(150) NOT NULL,
    email          VARCHAR(150) NOT NULL,
    phone          VARCHAR(20),
    password_hash  VARCHAR(255) NOT NULL,
    avatar         TEXT,
    status         VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE roles (
    role_id      SERIAL PRIMARY KEY,
    role_name    VARCHAR(50) NOT NULL,
    description  TEXT
);

CREATE TABLE user_roles (
    user_id  UUID NOT NULL,
    role_id  INT  NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

-- ------------------------------------------------------------
-- Nhóm 2: Family & Genealogy
-- ------------------------------------------------------------
CREATE TABLE families (
    family_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_name   VARCHAR(200) NOT NULL,
    origin_story  TEXT,
    created_by    UUID,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE branches (
    branch_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_name       VARCHAR(200) NOT NULL,
    family_id         UUID NOT NULL,
    parent_branch_id  UUID
);

CREATE TABLE family_members (
    member_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name             VARCHAR(150) NOT NULL,
    birth_date            DATE,
    death_date            DATE,
    gender                VARCHAR(10),
    occupation            VARCHAR(150),
    education_level       VARCHAR(100),
    location              VARCHAR(200),
    generation_level      INT,
    verification_status   VARCHAR(20) NOT NULL DEFAULT 'pending',
    verified_by           UUID,
    verified_at           TIMESTAMP,
    family_id             UUID NOT NULL,
    branch_id             UUID,
    user_id               UUID
);

CREATE TABLE relationships (
    rel_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id_a    UUID NOT NULL,
    member_id_b    UUID NOT NULL,
    relation_type  VARCHAR(20) NOT NULL
);

CREATE TABLE marriages (
    marriage_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id_1    UUID NOT NULL,
    member_id_2    UUID NOT NULL,
    marriage_date  DATE,
    status         VARCHAR(20)
);

-- ------------------------------------------------------------
-- Nhóm 3: Community
-- ------------------------------------------------------------
CREATE TABLE posts (
    post_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id   UUID NOT NULL,
    family_id   UUID NOT NULL,
    content     TEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    comment_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID NOT NULL,
    user_id     UUID NOT NULL,
    content     TEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reactions (
    reaction_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID NOT NULL,
    user_id         UUID NOT NULL,
    reaction_type   VARCHAR(20) NOT NULL
);

CREATE TABLE photos (
    photo_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id      UUID NOT NULL,
    url          TEXT NOT NULL,
    uploaded_by  UUID,
    uploaded_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Nhóm 4: Events
-- ------------------------------------------------------------
CREATE TABLE events (
    event_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id    UUID NOT NULL,
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    start_time   TIMESTAMP,
    location     VARCHAR(200),
    created_by   UUID NOT NULL
);

CREATE TABLE event_participants (
    event_id     UUID NOT NULL,
    user_id      UUID NOT NULL,
    rsvp_status  VARCHAR(10) NOT NULL DEFAULT 'maybe',
    PRIMARY KEY (event_id, user_id)
);

CREATE TABLE event_galleries (
    gallery_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id     UUID NOT NULL,
    url          TEXT NOT NULL,
    uploaded_by  UUID,
    uploaded_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE event_reminders (
    reminder_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id     UUID NOT NULL,
    user_id      UUID NOT NULL,
    remind_at    TIMESTAMP NOT NULL,
    method       VARCHAR(10) NOT NULL DEFAULT 'push',
    status       VARCHAR(10) NOT NULL DEFAULT 'pending'
);

-- ------------------------------------------------------------
-- Nhóm 5 & 6: Family Directory & Family Heritage
-- ------------------------------------------------------------
CREATE TABLE historical_documents (
    doc_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id    UUID NOT NULL,
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    file_url     TEXT,
    category     VARCHAR(30) NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE family_stories (
    story_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id   UUID NOT NULL,
    title       VARCHAR(200) NOT NULL,
    content     TEXT,
    author_id   UUID,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE archives (
    archive_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id    UUID NOT NULL,
    title        VARCHAR(200) NOT NULL,
    file_url     TEXT NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- Nhóm 7 & 8: AI-assisted Services & Dashboard/Administration
-- ------------------------------------------------------------
CREATE TABLE ai_query_logs (
    log_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL,
    query_text         TEXT NOT NULL,
    query_type         VARCHAR(30) NOT NULL,
    response_summary   TEXT,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ai_recommendations (
    rec_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL,
    target_type  VARCHAR(20) NOT NULL,
    target_id    UUID NOT NULL,
    score        NUMERIC(5,4),
    reason       TEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
    log_id        BIGSERIAL PRIMARY KEY,
    user_id       UUID,
    action        VARCHAR(50) NOT NULL,
    target_table  VARCHAR(100),
    target_id     UUID,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reports (
    report_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type    VARCHAR(50) NOT NULL,
    file_url       TEXT,
    generated_by   UUID,
    generated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE system_configs (
    config_key    VARCHAR(100) PRIMARY KEY,
    config_value  TEXT NOT NULL,
    description   TEXT,
    updated_by    UUID,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. THIẾT LẬP CONSTRAINT — 3.1 Khóa ngoại (FOREIGN KEY)
-- ============================================================
ALTER TABLE user_roles
  ADD CONSTRAINT fk_userroles_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE user_roles
  ADD CONSTRAINT fk_userroles_role FOREIGN KEY (role_id) REFERENCES roles(role_id);

ALTER TABLE families
  ADD CONSTRAINT fk_families_creator FOREIGN KEY (created_by) REFERENCES users(user_id);

ALTER TABLE branches
  ADD CONSTRAINT fk_branches_family FOREIGN KEY (family_id) REFERENCES families(family_id);
ALTER TABLE branches
  ADD CONSTRAINT fk_branches_parent FOREIGN KEY (parent_branch_id) REFERENCES branches(branch_id);

ALTER TABLE family_members
  ADD CONSTRAINT fk_members_family FOREIGN KEY (family_id) REFERENCES families(family_id);
ALTER TABLE family_members
  ADD CONSTRAINT fk_members_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id);
ALTER TABLE family_members
  ADD CONSTRAINT fk_members_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE family_members
  ADD CONSTRAINT fk_members_verifier FOREIGN KEY (verified_by) REFERENCES users(user_id);

ALTER TABLE relationships
  ADD CONSTRAINT fk_rel_member_a FOREIGN KEY (member_id_a) REFERENCES family_members(member_id);
ALTER TABLE relationships
  ADD CONSTRAINT fk_rel_member_b FOREIGN KEY (member_id_b) REFERENCES family_members(member_id);

ALTER TABLE marriages
  ADD CONSTRAINT fk_marriage_member1 FOREIGN KEY (member_id_1) REFERENCES family_members(member_id);
ALTER TABLE marriages
  ADD CONSTRAINT fk_marriage_member2 FOREIGN KEY (member_id_2) REFERENCES family_members(member_id);

ALTER TABLE posts
  ADD CONSTRAINT fk_posts_author FOREIGN KEY (author_id) REFERENCES users(user_id);
ALTER TABLE posts
  ADD CONSTRAINT fk_posts_family FOREIGN KEY (family_id) REFERENCES families(family_id);

ALTER TABLE comments
  ADD CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts(post_id);
ALTER TABLE comments
  ADD CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE reactions
  ADD CONSTRAINT fk_reactions_post FOREIGN KEY (post_id) REFERENCES posts(post_id);
ALTER TABLE reactions
  ADD CONSTRAINT fk_reactions_user FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE photos
  ADD CONSTRAINT fk_photos_post FOREIGN KEY (post_id) REFERENCES posts(post_id);
ALTER TABLE photos
  ADD CONSTRAINT fk_photos_uploader FOREIGN KEY (uploaded_by) REFERENCES users(user_id);

ALTER TABLE events
  ADD CONSTRAINT fk_events_family FOREIGN KEY (family_id) REFERENCES families(family_id);
ALTER TABLE events
  ADD CONSTRAINT fk_events_creator FOREIGN KEY (created_by) REFERENCES users(user_id);

ALTER TABLE event_participants
  ADD CONSTRAINT fk_ep_event FOREIGN KEY (event_id) REFERENCES events(event_id);
ALTER TABLE event_participants
  ADD CONSTRAINT fk_ep_user FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE event_galleries
  ADD CONSTRAINT fk_gallery_event FOREIGN KEY (event_id) REFERENCES events(event_id);
ALTER TABLE event_galleries
  ADD CONSTRAINT fk_gallery_uploader FOREIGN KEY (uploaded_by) REFERENCES users(user_id);

ALTER TABLE event_reminders
  ADD CONSTRAINT fk_reminder_event FOREIGN KEY (event_id) REFERENCES events(event_id);
ALTER TABLE event_reminders
  ADD CONSTRAINT fk_reminder_user FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE historical_documents
  ADD CONSTRAINT fk_doc_family FOREIGN KEY (family_id) REFERENCES families(family_id);

ALTER TABLE family_stories
  ADD CONSTRAINT fk_story_family FOREIGN KEY (family_id) REFERENCES families(family_id);
ALTER TABLE family_stories
  ADD CONSTRAINT fk_story_author FOREIGN KEY (author_id) REFERENCES users(user_id);

ALTER TABLE archives
  ADD CONSTRAINT fk_archive_family FOREIGN KEY (family_id) REFERENCES families(family_id);

ALTER TABLE ai_query_logs
  ADD CONSTRAINT fk_query_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ai_recommendations
  ADD CONSTRAINT fk_rec_user FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE audit_logs
  ADD CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE reports
  ADD CONSTRAINT fk_report_user FOREIGN KEY (generated_by) REFERENCES users(user_id);
ALTER TABLE system_configs
  ADD CONSTRAINT fk_config_user FOREIGN KEY (updated_by) REFERENCES users(user_id);

-- ------------------------------------------------------------
-- 3.2 Ràng buộc duy nhất (UNIQUE)
-- ------------------------------------------------------------
ALTER TABLE users
  ADD CONSTRAINT uq_users_email UNIQUE (email);
ALTER TABLE roles
  ADD CONSTRAINT uq_roles_name UNIQUE (role_name);
ALTER TABLE family_members
  ADD CONSTRAINT uq_members_user UNIQUE (user_id);
ALTER TABLE reactions
  ADD CONSTRAINT uq_reactions_post_user UNIQUE (post_id, user_id);
ALTER TABLE relationships
  ADD CONSTRAINT uq_relationship_pair
  UNIQUE (member_id_a, member_id_b, relation_type);

-- ------------------------------------------------------------
-- 3.3 Ràng buộc miền giá trị (CHECK)
-- ------------------------------------------------------------
ALTER TABLE users
  ADD CONSTRAINT ck_users_status
  CHECK (status IN ('active','inactive','banned'));

ALTER TABLE branches
  ADD CONSTRAINT ck_branch_not_self
  CHECK (branch_id <> parent_branch_id);

ALTER TABLE family_members
  ADD CONSTRAINT ck_members_verify
  CHECK (verification_status IN ('pending','verified','rejected'));

ALTER TABLE relationships
  ADD CONSTRAINT ck_rel_not_self
  CHECK (member_id_a <> member_id_b);
ALTER TABLE relationships
  ADD CONSTRAINT ck_rel_type
  CHECK (relation_type IN ('parent','child','sibling'));

ALTER TABLE marriages
  ADD CONSTRAINT ck_marriage_not_self
  CHECK (member_id_1 <> member_id_2);
ALTER TABLE marriages
  ADD CONSTRAINT ck_marriage_status
  CHECK (status IN ('married','divorced','widowed'));

ALTER TABLE event_participants
  ADD CONSTRAINT ck_ep_rsvp
  CHECK (rsvp_status IN ('yes','no','maybe'));

ALTER TABLE event_reminders
  ADD CONSTRAINT ck_reminder_method
  CHECK (method IN ('push','email','sms'));
ALTER TABLE event_reminders
  ADD CONSTRAINT ck_reminder_status
  CHECK (status IN ('pending','sent'));

ALTER TABLE historical_documents
  ADD CONSTRAINT ck_doc_category
  CHECK (category IN ('document','notable_member'));

ALTER TABLE ai_query_logs
  ADD CONSTRAINT ck_query_type
  CHECK (query_type IN ('search','assistant','summarization',
                         'relationship_explain'));

ALTER TABLE ai_recommendations
  ADD CONSTRAINT ck_rec_target_type
  CHECK (target_type IN ('member','post','document'));

-- ============================================================
-- 4. TẠO INDEX — 4.1 Chỉ mục trên khóa ngoại
-- ============================================================
CREATE INDEX idx_families_created_by  ON families(created_by);
CREATE INDEX idx_branches_family      ON branches(family_id);
CREATE INDEX idx_branches_parent      ON branches(parent_branch_id);
CREATE INDEX idx_members_family       ON family_members(family_id);
CREATE INDEX idx_members_branch       ON family_members(branch_id);
CREATE INDEX idx_members_verified_by  ON family_members(verified_by);
CREATE INDEX idx_rel_member_a         ON relationships(member_id_a);
CREATE INDEX idx_rel_member_b         ON relationships(member_id_b);
CREATE INDEX idx_marriage_member1     ON marriages(member_id_1);
CREATE INDEX idx_marriage_member2     ON marriages(member_id_2);
CREATE INDEX idx_posts_author         ON posts(author_id);
CREATE INDEX idx_comments_user        ON comments(user_id);
CREATE INDEX idx_reactions_post       ON reactions(post_id);
CREATE INDEX idx_photos_post          ON photos(post_id);
CREATE INDEX idx_events_creator       ON events(created_by);
CREATE INDEX idx_ep_user              ON event_participants(user_id);
CREATE INDEX idx_gallery_event        ON event_galleries(event_id);
CREATE INDEX idx_reminder_event       ON event_reminders(event_id);
CREATE INDEX idx_doc_family           ON historical_documents(family_id);
CREATE INDEX idx_story_family         ON family_stories(family_id);
CREATE INDEX idx_story_author         ON family_stories(author_id);
CREATE INDEX idx_archive_family       ON archives(family_id);
CREATE INDEX idx_audit_user           ON audit_logs(user_id);
CREATE INDEX idx_report_user          ON reports(generated_by);
CREATE INDEX idx_config_user          ON system_configs(updated_by);

-- ------------------------------------------------------------
-- 4.2 Chỉ mục phục vụ truy vấn nghiệp vụ thường xuyên
-- ------------------------------------------------------------
CREATE INDEX idx_posts_family_created ON posts(family_id, created_at DESC);
CREATE INDEX idx_comments_post        ON comments(post_id, created_at);
CREATE INDEX idx_events_family_start  ON events(family_id, start_time);
CREATE INDEX idx_reminder_user_time   ON event_reminders(user_id, remind_at);
CREATE INDEX idx_query_user_time      ON ai_query_logs(user_id, created_at DESC);
CREATE INDEX idx_rec_user_score       ON ai_recommendations(user_id, score DESC);
CREATE INDEX idx_audit_table_target   ON audit_logs(target_table, target_id);

-- ------------------------------------------------------------
-- 4.3 Chỉ mục phục vụ tra cứu Family Directory
-- ------------------------------------------------------------
CREATE INDEX idx_members_occupation  ON family_members(occupation);
CREATE INDEX idx_members_location    ON family_members(location);
CREATE INDEX idx_members_generation  ON family_members(family_id, generation_level);

-- ------------------------------------------------------------
-- 4.4 Chỉ mục tìm kiếm gần đúng và tìm kiếm toàn văn
-- ------------------------------------------------------------
CREATE INDEX idx_members_fullname_trgm ON family_members USING GIN (full_name gin_trgm_ops);
CREATE INDEX idx_posts_content_fts     ON posts USING GIN (to_tsvector('simple', content));
CREATE INDEX idx_story_content_fts     ON family_stories USING GIN (to_tsvector('simple', content));
