-- Migrations to mirror the Flutter app's Firestore data model onto the local API.

USE quizflow;

-- Questions: allow standalone rows (question bank, no quiz), plus app columns
ALTER TABLE questions
  MODIFY COLUMN quiz_id INT(11) NULL COMMENT 'FK -> quizzes.quiz_id (nullable)',
  ADD COLUMN IF NOT EXISTS difficulty VARCHAR(20)  NULL COMMENT 'easy|medium|hard',
  ADD COLUMN IF NOT EXISTS status     VARCHAR(20)  NOT NULL DEFAULT 'approved' COMMENT 'approved|inReview|draft',
  ADD COLUMN IF NOT EXISTS course     VARCHAR(100) NULL COMMENT 'Subject/course',
  ADD COLUMN IF NOT EXISTS created_at DATETIME     NULL COMMENT 'Creation date';

-- Users: add createdAt so app lists can sort
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS created_at DATETIME NULL COMMENT 'Creation date';

-- Results: expose total and percentage for the app UI
ALTER TABLE results
  ADD COLUMN IF NOT EXISTS total_questions INT(5) NOT NULL DEFAULT 0 COMMENT 'Total questions considered',
  ADD COLUMN IF NOT EXISTS percentage      DECIMAL(5,1) NOT NULL DEFAULT 0 COMMENT 'Score %';