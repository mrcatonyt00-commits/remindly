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

$item_id = intval($data['item_id'] ?? 0);
$checked = isset($data['checked']) ? (bool)$data['checked'] : false;

if ($item_id == 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Item ID is required']);
    exit;
}

// Update item status
$sql = "UPDATE checklist_items SET checked = ? WHERE id = ?";
$stmt = $conn->prepare($sql);
$checked_int = $checked ? 1 : 0;
$stmt->bind_param("ii", $checked_int, $item_id);

if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Item updated']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to update item']);
}

$stmt->close();
$conn->close();
?>