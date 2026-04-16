<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require '../PHPMailer/Exception.php';
require '../PHPMailer/PHPMailer.php';
require '../PHPMailer/SMTP.php';
require '../config.php';

// Set timezone (already in config.php but setting here too for safety)
date_default_timezone_set('Asia/Manila'); // CHANGE THIS to your timezone

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

// Check if email exists
$check_sql = "SELECT id FROM users WHERE email = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $email);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows == 0) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Email not found']);
    exit;
}

$user_row = $check_result->fetch_assoc();
$user_id = $user_row['id'];

// Generate OTP - exactly 6 digits
$otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

// Get current time and add 10 minutes
$current_time = new DateTime();
$current_time->add(new DateInterval('PT10M')); // Add 10 minutes
$otp_expires = $current_time->format('Y-m-d H:i:s');

// Debug log
error_log("Current time: " . (new DateTime())->format('Y-m-d H:i:s'));
error_log("OTP expires at: " . $otp_expires);
error_log("OTP: " . $otp);

// Save OTP to database
$update_sql = "UPDATE users SET otp = ?, otp_expires_at = ? WHERE id = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("ssi", $otp, $otp_expires, $user_id);

if (!$update_stmt->execute()) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to save OTP']);
    exit;
}

// Send OTP via email using PHPMailer
try {
    $mail = new PHPMailer(true);
    $mail->isSMTP();
    $mail->Host = MAIL_HOST;
    $mail->SMTPAuth = true;
    $mail->Username = MAIL_USERNAME;
    $mail->Password = MAIL_PASSWORD;
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = MAIL_PORT;

    $mail->setFrom(MAIL_FROM_EMAIL, MAIL_FROM_NAME);
    $mail->addAddress($email);
    $mail->Subject = 'Remindly - Password Reset Code';
    
    $mail->isHTML(true);
    $mail->Body = "
    <html>
    <body style='font-family: Arial, sans-serif;'>
        <h2>Password Reset Code</h2>
        <p>Your password reset code is:</p>
        <h1 style='color: #667eea; font-size: 36px; letter-spacing: 5px; text-align: center;'>$otp</h1>
        <p>This code will expire in 10 minutes.</p>
        <p>If you didn't request this, please ignore this email.</p>
        <br>
        <p>Best regards,<br><strong>Remindly Team</strong></p>
    </body>
    </html>
    ";

    $mail->AltBody = "Your password reset code is: $otp (Valid for 10 minutes)";

    $mail->send();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'OTP sent to your email']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to send email: ' . $mail->ErrorInfo]);
}

$check_stmt->close();
$update_stmt->close();
$conn->close();
?>