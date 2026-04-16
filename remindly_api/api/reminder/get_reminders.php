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

// Get all reminders for user, ordered by date
$sql = "SELECT id, title, description, checklist_id, reminder_date, reminder_time, repeat_type, active, created_at 
        FROM reminders 
        WHERE user_id = ? 
        ORDER BY reminder_date ASC, reminder_time ASC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$reminders = [];
while ($row = $result->fetch_assoc()) {
    $reminders[] = [
        'id' => $row['id'],
        'title' => $row['title'],
        'description' => $row['description'],
        'checklist_id' => $row['checklist_id'],
        'reminder_date' => $row['reminder_date'],
        'reminder_time' => $row['reminder_time'],
        'repeat_type' => $row['repeat_type'],
        'active' => (bool)$row['active'],
        'created_at' => $row['created_at']
    ];
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'data' => $reminders
]);

$stmt->close();
$conn->close();
?>