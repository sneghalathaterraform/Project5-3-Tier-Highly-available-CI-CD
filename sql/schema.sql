-- Run once on RDS after terraform apply
CREATE DATABASE IF NOT EXISTS libraryhub CHARACTER SET utf8mb4;
USE libraryhub;

-- Part 1: library registrations
CREATE TABLE IF NOT EXISTS libraries (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  phone      VARCHAR(30)  NOT NULL,
  email      VARCHAR(255) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Part 2: books catalog
CREATE TABLE IF NOT EXISTS books (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title            VARCHAR(255) NOT NULL,
  author           VARCHAR(255) NOT NULL,
  available_copies TINYINT UNSIGNED NOT NULL DEFAULT 1
);

INSERT IGNORE INTO books (id, title, author, available_copies) VALUES
(1, 'The Great Gatsby',      'F. Scott Fitzgerald', 2),
(2, '1984',                  'George Orwell',        0),
(3, 'To Kill a Mockingbird', 'Harper Lee',           1),
(4, 'The Hobbit',            'J.R.R. Tolkien',       3),
(5, 'Pride and Prejudice',   'Jane Austen',          1),
(6, 'Harry Potter (Book 1)', 'J.K. Rowling',         0),
(7, 'The Alchemist',         'Paulo Coelho',          2),
(8, 'Brave New World',       'Aldous Huxley',         1);
