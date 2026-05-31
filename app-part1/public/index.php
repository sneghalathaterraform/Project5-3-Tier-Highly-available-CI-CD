<?php
function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $host = $_SERVER['DB_HOST']     ?? getenv('DB_HOST')     ?? '127.0.0.1';
        $name = $_SERVER['DB_NAME']     ?? getenv('DB_NAME')     ?? 'libraryhub';
        $user = $_SERVER['DB_USER']     ?? getenv('DB_USER')     ?? 'admin';
        $pass = $_SERVER['DB_PASSWORD'] ?? getenv('DB_PASSWORD') ?? '';
        $pdo = new PDO(
            "mysql:host=$host;dbname=$name;charset=utf8mb4",
            $user,
            $pass,
            [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]
        );
    }
    return $pdo;
}

$success = false;
$errors  = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name  = trim($_POST['name']  ?? '');
    $phone = trim($_POST['phone'] ?? '');
    $email = trim($_POST['email'] ?? '');

    if (!$name)  $errors[] = 'Library name is required.';
    if (!$phone) $errors[] = 'Contact number is required.';
    if (!filter_var($email, FILTER_VALIDATE_EMAIL))
        $errors[] = 'A valid email is required.';

    if (!$errors) {
        db()->prepare("INSERT INTO libraries (name, phone, email) VALUES (?, ?, ?)")
           ->execute([$name, $phone, strtolower($email)]);
        $success = true;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LibraryHub – Register</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<nav class="navbar navbar-dark bg-primary px-4">
  <span class="navbar-brand fw-bold">📚 LibraryHub</span>
</nav>
<div class="container py-5">
  <div class="row justify-content-center">
    <div class="col-md-5">

      <?php if ($success): ?>
      <div class="card border-0 shadow-sm text-center py-5">
        <div class="card-body">
          <div class="display-4 mb-2">✅</div>
          <h4 class="fw-bold text-success">Registered!</h4>
          <p class="text-muted">Your library has been saved to the database.</p>
          <a href="/" class="btn btn-primary mt-2">Register Another</a>
        </div>
      </div>
      <?php else: ?>
      <div class="card border-0 shadow-sm">
        <div class="card-header bg-primary text-white fw-semibold">
          Library Registration
        </div>
        <div class="card-body p-4">
          <?php foreach ($errors as $e): ?>
            <div class="alert alert-danger py-2 small"><?= htmlspecialchars($e) ?></div>
          <?php endforeach; ?>
          <form method="POST" novalidate>
            <div class="mb-3">
              <label class="form-label fw-semibold">Library Name <span class="text-danger">*</span></label>
              <input type="text" name="name" class="form-control"
                     placeholder="e.g. City Central Library"
                     value="<?= htmlspecialchars($_POST['name'] ?? '') ?>">
            </div>
            <div class="mb-3">
              <label class="form-label fw-semibold">Contact Number <span class="text-danger">*</span></label>
              <input type="tel" name="phone" class="form-control"
                     placeholder="e.g. +1 416-000-0000"
                     value="<?= htmlspecialchars($_POST['phone'] ?? '') ?>">
            </div>
            <div class="mb-4">
              <label class="form-label fw-semibold">Email Address <span class="text-danger">*</span></label>
              <input type="email" name="email" class="form-control"
                     placeholder="e.g. info@library.com"
                     value="<?= htmlspecialchars($_POST['email'] ?? '') ?>">
            </div>
            <button type="submit" class="btn btn-primary w-100 py-2">Register Library</button>
          </form>
        </div>
      </div>
      <?php endif; ?>

    </div>
  </div>
</div>
</body>
</html>