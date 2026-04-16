<?php
$host = 'localhost';
$db = 'remindly';
$user = 'root';
$password = '';

$conn = new mysqli($host, $user, $password, $db);

if ($conn->connect_error) {
    die('Database connection failed');
}

$token = isset($_GET['token']) ? trim($_GET['token']) : '';

if (empty($token)) {
    $message = 'Invalid verification link.';
    $success = false;
} else {
    // Find user with this token
    $sql = "SELECT id FROM users WHERE verification_token = ? AND token_expires_at > NOW() AND is_verified = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 0) {
        $message = 'Invalid or expired verification link.';
        $success = false;
    } else {
        $user_row = $result->fetch_assoc();
        $user_id = $user_row['id'];

        // Update user to verified
        $update_sql = "UPDATE users SET is_verified = 1, verification_token = NULL, token_expires_at = NULL WHERE id = ?";
        $update_stmt = $conn->prepare($update_sql);
        $update_stmt->bind_param("i", $user_id);

        if ($update_stmt->execute()) {
            $message = 'Email verified successfully! You can now sign in to Remindly.';
            $success = true;
        } else {
            $message = 'Verification failed. Please try again.';
            $success = false;
        }
        $update_stmt->close();
    }
    $stmt->close();
}

$conn->close();
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification - Remindly</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            text-align: center;
            max-width: 400px;
        }
        .icon {
            font-size: 50px;
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
            margin-bottom: 15px;
        }
        p {
            color: #666;
            margin-bottom: 30px;
        }
        .success { color: #4CAF50; }
        .error { color: #f44336; }
        a {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 30px;
            border-radius: 5px;
            text-decoration: none;
            margin-top: 20px;
        }
        a:hover {
            background: #764ba2;
        }
    </style>
</head>
<body>
    <div class="container">
        <?php if ($success): ?>
            <div class="icon">✓</div>
            <h1 class="success">Email Verified!</h1>
            <p><?php echo $message; ?></p>
            <a href="https://remindly.app">Go to Remindly</a>
        <?php else: ?>
            <div class="icon">✗</div>
            <h1 class="error">Verification Failed</h1>
            <p><?php echo $message; ?></p>
            <a href="https://remindly.app">Back to Remindly</a>
        <?php endif; ?>
    </div>
</body>
</html>