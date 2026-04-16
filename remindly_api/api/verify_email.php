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
$token = trim($data['token'] ?? '');

if (empty($token)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid verification token']);
    exit;
}

// Find user with this token and check if it's not expired
$sql = "SELECT id FROM users WHERE verification_token = ? AND token_expires_at > NOW() AND is_verified = 0";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $token);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid or expired verification token']);
    exit;
}

$user_row = $result->fetch_assoc();
$user_id = $user_row['id'];

// Update user to verified and clear token
$update_sql = "UPDATE users SET is_verified = 1, verification_token = NULL, token_expires_at = NULL WHERE id = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("i", $user_id);

if ($update_stmt->execute()) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Email verified successfully! You can now sign in.']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Verification failed']);
}

$stmt->close();
$update_stmt->close();
$conn->close();
?>