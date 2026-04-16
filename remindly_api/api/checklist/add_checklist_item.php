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

$checklist_id = intval($data['checklist_id'] ?? 0);
$text = trim($data['text'] ?? '');

if ($checklist_id == 0 || empty($text)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Checklist ID and text are required']);
    exit;
}

// Insert item
$sql = "INSERT INTO checklist_items (checklist_id, text) VALUES (?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("is", $checklist_id, $text);

if ($stmt->execute()) {
    $item_id = $stmt->insert_id;
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Item added',
        'item_id' => $item_id
    ]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to add item']);
}

$stmt->close();
$conn->close();
?>