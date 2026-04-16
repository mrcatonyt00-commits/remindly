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

// Get all alerts for user, unread first
$sql = "SELECT id, reminder_id, alert_title, alert_date, alert_time, alert_type, is_read, created_at 
        FROM alerts 
        WHERE user_id = ? 
        ORDER BY is_read ASC, alert_date DESC, alert_time DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$alerts = [];
while ($row = $result->fetch_assoc()) {
    $alerts[] = [
        'id' => $row['id'],
        'reminder_id' => $row['reminder_id'],
        'alert_title' => $row['alert_title'],
        'alert_date' => $row['alert_date'],
        'alert_time' => $row['alert_time'],
        'alert_type' => $row['alert_type'],
        'is_read' => (bool)$row['is_read'],
        'created_at' => $row['created_at']
    ];
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'data' => $alerts
]);

$stmt->close();
$conn->close();
?>