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

if (empty($email)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email is required']);
    exit;
}

// Check if email exists in database
$check_sql = "SELECT id FROM users WHERE email = ? AND is_verified = 1";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $email);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows > 0) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Email found']);
} else {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Email not found. Please check if you registered with this email.']);
}

$check_stmt->close();
$conn->close();
?>