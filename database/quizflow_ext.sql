-- QuizFlow app extensions on top of the project spec (قاعده البيانات للمشروع.docx)
-- Needed so the Flutter app features match the local database.

USE quizflow;

-- Sessions table for API token auth
CREATE TABLE IF NOT EXISTS sessions (
  token      VARCHAR(64) NOT NULL COMMENT 'API session token',
  user_id    INT(11)     NOT NULL COMMENT 'FK -> users.user_id',
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (token),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Subjects (app feature; the spec has no subject table, this is an extension)
CREATE TABLE IF NOT EXISTS subjects (
  subject_id INT(11)      NOT NULL AUTO_INCREMENT COMMENT 'PK',
  name       VARCHAR(100) NOT NULL COMMENT 'Subject name',
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (subject_id),
  UNIQUE KEY uk_subjects_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- App columns on quizzes (course subject + max attempts; spec only defines title/teacher/duration/date)
ALTER TABLE quizzes
  ADD COLUMN IF NOT EXISTS course       VARCHAR(100) NULL COMMENT 'Subject/course',
  ADD COLUMN IF NOT EXISTS max_attempts INT(5) NOT NULL DEFAULT 1 COMMENT 'Max attempts',
  ADD COLUMN IF NOT EXISTS published    TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Published flag';