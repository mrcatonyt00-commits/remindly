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
$email = trim($data['email'] ?? '');

if (empty($email)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email is required']);
    exit;
}

// Check if user exists and is not verified
$check_sql = "SELECT id, name FROM users WHERE email = ? AND is_verified = 0";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $email);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows == 0) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Email not found or already verified']);
    exit;
}

$user_row = $check_result->fetch_assoc();
$user_id = $user_row['id'];
$name = $user_row['name'];

// Generate new verification token
$verification_token = bin2hex(random_bytes(32));
$token_expires = date('Y-m-d H:i:s', strtotime('+24 hours'));

// Update user with new token
$update_sql = "UPDATE users SET verification_token = ?, token_expires_at = ? WHERE id = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("ssi", $verification_token, $token_expires, $user_id);
$update_stmt->execute();

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
        <h2>Email Verification</h2>
        <p>Hello <strong>$name</strong>,</p>
        <p>Please verify your email address by clicking the button below:</p>
        <p><a href='$verification_link' style='background-color: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;'>Verify Email Address</a></p>
        <p>Or copy this link: <br><code style='word-break: break-all;'>$verification_link</code></p>
        <p>This link will expire in 24 hours.</p>
        <p>If you didn't request this, please ignore this email.</p>
        <br>
        <p>Best regards,<br><strong>Remindly Team</strong></p>
    </body>
    </html>
    ";

    $mail->AltBody = "Verify your email: $verification_link";

    $mail->send();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Verification email sent']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to send email: ' . $mail->ErrorInfo]);
}

$check_stmt->close();
$update_stmt->close();
$conn->close();
?>