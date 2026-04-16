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

if (empty($email) || empty($otp)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email and OTP are required']);
    exit;
}

// Verify OTP - check if it matches and is not expired
$sql = "SELECT id FROM users WHERE email = ? AND otp = ? AND otp_expires_at > NOW()";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $email, $otp);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP. Please request a new one.']);
    exit;
}

// OTP is valid - return success
http_response_code(200);
echo json_encode(['success' => true, 'message' => 'OTP verified']);

$stmt->close();
$conn->close();
?>