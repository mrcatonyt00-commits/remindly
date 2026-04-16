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

$username = trim($data['username'] ?? '');
$password_plain = $data['password'] ?? '';

if (empty($username) || empty($password_plain)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Username and password are required']);
    exit;
}

$sql = "SELECT id, name, username, email, password, is_verified FROM users WHERE username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user_data = $result->fetch_assoc();
    
    // Check if email is verified
    if ($user_data['is_verified'] == 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Please verify your email before signing in. Check your inbox for the verification link.']);
        exit;
    }
    
    if (password_verify($password_plain, $user_data['password'])) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'user' => [
                'id' => $user_data['id'],
                'name' => $user_data['name'],
                'username' => $user_data['username'],
                'email' => $user_data['email'],
                'is_verified' => $user_data['is_verified']
            ]
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid password']);
    }
} else {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'User not found']);
}

$stmt->close();
$conn->close();
?>