<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require '../../config.php';

$conn = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

$data = json_decode(file_get_contents("php://input"), true);

$user_id = intval($data['user_id'] ?? 0);
$title = trim($data['title'] ?? '');
$category = trim($data['category'] ?? '');

if ($user_id == 0 || empty($title)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'User ID and title are required']);
    exit;
}

// Insert checklist
$sql = "INSERT INTO checklists (user_id, title, category) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("iss", $user_id, $title, $category);

if ($stmt->execute()) {
    $checklist_id = $stmt->insert_id;
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Checklist created',
        'checklist_id' => $checklist_id
    ]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to create checklist']);
}

$stmt->close();
$conn->close();
?>