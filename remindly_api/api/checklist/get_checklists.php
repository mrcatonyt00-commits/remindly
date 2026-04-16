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

if ($user_id == 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'User ID is required']);
    exit;
}

// Get all checklists for user
$sql = "SELECT id, title, category, created_at FROM checklists WHERE user_id = ? ORDER BY created_at DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$checklists = [];
while ($row = $result->fetch_assoc()) {
    // Get items for each checklist
    $items_sql = "SELECT id, text, checked FROM checklist_items WHERE checklist_id = ?";
    $items_stmt = $conn->prepare($items_sql);
    $items_stmt->bind_param("i", $row['id']);
    $items_stmt->execute();
    $items_result = $items_stmt->get_result();
    
    $items = [];
    while ($item = $items_result->fetch_assoc()) {
        $items[] = [
            'id' => $item['id'],
            'text' => $item['text'],
            'checked' => (bool)$item['checked']
        ];
    }
    
    $row['items'] = $items;
    $checklists[] = $row;
    $items_stmt->close();
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'data' => $checklists
]);

$stmt->close();
$conn->close();
?>