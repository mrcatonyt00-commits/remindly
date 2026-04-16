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
$reminder_id = intval($data['reminder_id'] ?? 0);

if ($reminder_id == 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Reminder ID is required']);
    exit;
}

// Delete reminder (alerts will auto-delete due to CASCADE)
$sql = "DELETE FROM reminders WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $reminder_id);

if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Reminder deleted']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to delete reminder']);
}

$stmt->close();
$conn->close();
?>