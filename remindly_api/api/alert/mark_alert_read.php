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
$alert_id = intval($data['alert_id'] ?? 0);

if ($alert_id == 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Alert ID is required']);
    exit;
}

// Mark alert as read
$sql = "UPDATE alerts SET is_read = 1 WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $alert_id);

if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Alert marked as read']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to update alert']);
}

$stmt->close();
$conn->close();
?>