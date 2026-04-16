<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$host = 'localhost';
$db = 'remindly';
$user = 'root';
$password = '';

$conn = new mysqli($host, $user, $password, $db);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents("php://input"), true);

$email = trim($data['email'] ?? '');
$otp = trim($data['otp'] ?? '');
$new_password = $data['new_password'] ?? '';

if (empty($email) || empty($otp) || empty($new_password)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'All fields are required']);
    exit;
}

// Verify OTP is valid and not expired
$sql = "SELECT id FROM users WHERE email = ? AND otp = ? AND otp_expires_at > NOW()";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $email, $otp);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP']);
    exit;
}

$user_row = $result->fetch_assoc();
$user_id = $user_row['id'];

// Hash the new password
$hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

// Update password and clear OTP
$update_sql = "UPDATE users SET password = ?, otp = NULL, otp_expires_at = NULL WHERE id = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("si", $hashed_password, $user_id);

if ($update_stmt->execute()) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Password reset successful! You can now sign in with your new password.']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to reset password']);
}

$stmt->close();
$update_stmt->close();
$conn->close();
?>