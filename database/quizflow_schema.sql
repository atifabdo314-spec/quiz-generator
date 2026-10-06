-- QuizFlow database schema per "قاعده البيانات للمشروع.docx"
-- Database: quizflow  (utf8mb4 for Arabic support)

CREATE DATABASE IF NOT EXISTS quizflow
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE quizflow;

DROP TABLE IF EXISTS answer_details;
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS options;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS quizzes;
DROP TABLE IF EXISTS users;

-- Table 1: Users (System users and admin)
CREATE TABLE users (
  user_id   INT(11)      NOT NULL AUTO_INCREMENT COMMENT 'PK',
  username  VARCHAR(50)  NOT NULL COMMENT 'Username',
  password  VARCHAR(255) NOT NULL COMMENT 'Password',
  email     VARCHAR(100) NOT NULL COMMENT 'Email',
  role      VARCHAR(20)  NOT NULL COMMENT 'Role',
  PRIMARY KEY (user_id),
  UNIQUE KEY uk_users_email (email),
  UNIQUE KEY uk_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: Quizzes
CREATE TABLE quizzes (
  quiz_id      INT(11)      NOT NULL AUTO_INCREMENT COMMENT 'PK',
  title        VARCHAR(150) NOT NULL COMMENT 'Quiz title',
  teacher_id   INT(11)      NOT NULL COMMENT 'FK -> users.user_id',
  duration     INT(5)       NOT NULL COMMENT 'Duration in minutes',
  publish_date DATETIME     NOT NULL COMMENT 'Publish date',
  PRIMARY KEY (quiz_id),
  CONSTRAINT fk_quizzes_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: Question bank
CREATE TABLE questions (
  question_id   INT(11)      NOT NULL AUTO_INCREMENT COMMENT 'PK',
  quiz_id       INT(11)      NOT NULL COMMENT 'FK -> quizzes.quiz_id',
  question_text VARCHAR(255) NOT NULL COMMENT 'Question text',
  question_type VARCHAR(30)  NOT NULL COMMENT 'Question type',
  degree        INT(3)       NOT NULL COMMENT 'Question degree/score',
  PRIMARY KEY (question_id),
  CONSTRAINT fk_questions_quiz FOREIGN KEY (quiz_id)
    REFERENCES quizzes (quiz_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 4: Answer options
CREATE TABLE options (
  option_id   INT(11)      NOT NULL AUTO_INCREMENT COMMENT 'PK',
  question_id INT(11)      NOT NULL COMMENT 'FK -> questions.question_id',
  option_text VARCHAR(255) NOT NULL COMMENT 'Option text',
  is_correct  INT(1)       NOT NULL COMMENT '1 = correct, 0 = wrong',
  PRIMARY KEY (option_id),
  CONSTRAINT fk_options_question FOREIGN KEY (question_id)
    REFERENCES questions (question_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 5: Student results
CREATE TABLE results (
  result_id       INT(11)  NOT NULL AUTO_INCREMENT COMMENT 'PK',
  student_id      INT(11)  NOT NULL COMMENT 'FK -> users.user_id',
  quiz_id         INT(11)  NOT NULL COMMENT 'FK -> quizzes.quiz_id',
  total_score     INT(5)   NOT NULL COMMENT 'Total score',
  submission_date DATETIME NOT NULL COMMENT 'Submission date',
  PRIMARY KEY (result_id),
  CONSTRAINT fk_results_student FOREIGN KEY (student_id)
    REFERENCES users (user_id),
  CONSTRAINT fk_results_quiz FOREIGN KEY (quiz_id)
    REFERENCES quizzes (quiz_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 6: Answer details log
CREATE TABLE answer_details (
  answer_id          INT(11) NOT NULL AUTO_INCREMENT COMMENT 'PK',
  result_id          INT(11) NOT NULL COMMENT 'FK -> results.result_id',
  question_id        INT(11) NOT NULL COMMENT 'FK -> questions.question_id',
  selected_option_id INT(11) NOT NULL COMMENT 'FK -> options.option_id',
  PRIMARY KEY (answer_id),
  CONSTRAINT fk_answer_details_result FOREIGN KEY (result_id)
    REFERENCES results (result_id) ON DELETE CASCADE,
  CONSTRAINT fk_answer_details_question FOREIGN KEY (question_id)
    REFERENCES questions (question_id),
  CONSTRAINT fk_answer_details_option FOREIGN KEY (selected_option_id)
    REFERENCES options (option_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;