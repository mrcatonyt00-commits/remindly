<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require '../PHPMailer/Exception.php';
require '../PHPMailer/PHPMailer.php';
require '../PHPMailer/SMTP.php';
require '../config.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$conn = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents("php://input"), true);

$name = trim($data['name'] ?? '');
$username = trim($data['username'] ?? '');
$email = trim($data['email'] ?? '');
$password_plain = $data['password'] ?? '';

// Validation
if (empty($name) || empty($username) || empty($email) || empty($password_plain)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

if (strlen($password_plain) < 6) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Password must be at least 6 characters']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid email format']);
    exit;
}

// Check if username exists
$check_sql = "SELECT id FROM users WHERE username = ? OR email = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("ss", $username, $email);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows > 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Username or email already exists']);
    exit;
}

// Generate unique verification token
$verification_token = bin2hex(random_bytes(32));
$token_expires = date('Y-m-d H:i:s', strtotime('+24 hours'));

// Hash password
$hashed_password = password_hash($password_plain, PASSWORD_DEFAULT);

// Insert user with unverified status
$insert_sql = "INSERT INTO users (name, username, email, password, verification_token, token_expires_at, is_verified, created_at) VALUES (?, ?, ?, ?, ?, ?, 0, NOW())";
$insert_stmt = $conn->prepare($insert_sql);
$insert_stmt->bind_param("ssssss", $name, $username, $email, $hashed_password, $verification_token, $token_expires);

if ($insert_stmt->execute()) {
    // Send verification email using PHPMailer
    try {
        $mail = new PHPMailer(true);
        $mail->isSMTP();
        $mail->Host = MAIL_HOST;
        $mail->SMTPAuth = true;
        $mail->Username = MAIL_USERNAME;
        $mail->Password = MAIL_PASSWORD;
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = MAIL_PORT;

        $verification_link = VERIFY_LINK . $verification_token;

        $mail->setFrom(MAIL_FROM_EMAIL, MAIL_FROM_NAME);
        $mail->addAddress($email);
        $mail->Subject = 'Remindly - Verify Your Email';
        
        $mail->isHTML(true);
        $mail->Body = "
        <html>
        <body style='font-family: Arial, sans-serif;'>
            <h2>Welcome to Remindly!</h2>
            <p>Hello <strong>$name</strong>,</p>
            <p>Thank you for signing up. Please verify your email address by clicking the button below:</p>
            <p><a href='$verification_link' style='background-color: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;'>Verify Email Address</a></p>
            <p>Or copy this link: <br><code style='word-break: break-all;'>$verification_link</code></p>
            <p>This link will expire in 24 hours.</p>
            <p>If you didn't create this account, please ignore this email.</p>
            <br>
            <p>Best regards,<br><strong>Remindly Team</strong></p>
        </body>
        </html>
        ";

        $mail->AltBody = "Welcome to Remindly! Click this link to verify: $verification_link";

        $mail->send();

        http_response_code(201);
        echo json_encode(['success' => true, 'message' => 'Account created. Check your email to verify.']);
    } catch (Exception $e) {
        // Even if email fails, account is created
        http_response_code(201);
        echo json_encode(['success' => true, 'message' => 'Account created. Email may take a moment to arrive.']);
    }
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Registration failed']);
}

$check_stmt->close();
$insert_stmt->close();
$conn->close();
?>