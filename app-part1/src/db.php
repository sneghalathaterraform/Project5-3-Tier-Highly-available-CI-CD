<?php
function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            sprintf("mysql:host=%s;dbname=%s;charset=utf8mb4",
                getenv('DB_HOST') ?: '127.0.0.1',
                getenv('DB_NAME') ?: 'libraryhub'),
            getenv('DB_USER')     ?: 'admin',
            getenv('DB_PASSWORD') ?: '',
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
             PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );
    }
    return $pdo;
}
