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
$description = trim($data['description'] ?? '');
$reminder_date = trim($data['reminder_date'] ?? '');
$reminder_time = trim($data['reminder_time'] ?? '');
$repeat_type = trim($data['repeat_type'] ?? 'Never');
$checklist_id = !empty($data['checklist_id']) ? intval($data['checklist_id']) : null;

if ($user_id == 0 || empty($title) || empty($reminder_date) || empty($reminder_time)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

// Validate date format
if (!strtotime($reminder_date)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid date format']);
    exit;
}

// Insert reminder
$sql = "INSERT INTO reminders (user_id, title, description, checklist_id, reminder_date, reminder_time, repeat_type) 
        VALUES (?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ississs", $user_id, $title, $description, $checklist_id, $reminder_date, $reminder_time, $repeat_type);

if ($stmt->execute()) {
    $reminder_id = $stmt->insert_id;
    
    // Create 3 alerts automatically
    _createAlerts($conn, $user_id, $reminder_id, $title, $reminder_date, $reminder_time);
    
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Reminder created with alerts',
        'reminder_id' => $reminder_id
    ]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to create reminder']);
}

// Helper function to create 3 alerts
function _createAlerts($conn, $user_id, $reminder_id, $title, $date, $time) {
    $reminder_timestamp = strtotime("$date $time");
    
    // Alert 1: 30 minutes before
    $alert_30_timestamp = $reminder_timestamp - (30 * 60);
    $alert_30_date = date('Y-m-d', $alert_30_timestamp);
    $alert_30_time = date('H:i:s', $alert_30_timestamp);
    
    // Alert 2: 15 minutes before
    $alert_15_timestamp = $reminder_timestamp - (15 * 60);
    $alert_15_date = date('Y-m-d', $alert_15_timestamp);
    $alert_15_time = date('H:i:s', $alert_15_timestamp);
    
    // Alert 3: 5 minutes before
    $alert_5_timestamp = $reminder_timestamp - (5 * 60);
    $alert_5_date = date('Y-m-d', $alert_5_timestamp);
    $alert_5_time = date('H:i:s', $alert_5_timestamp);
    
    $sql = "INSERT INTO alerts (user_id, reminder_id, alert_title, alert_date, alert_time, alert_type) 
            VALUES (?, ?, ?, ?, ?, ?)";
    
    // Insert 30-min alert
    $stmt = $conn->prepare($sql);
    $alert_title = $title . " - 30 mins";
    $alert_type = "30-mins";
    $stmt->bind_param("iissss", $user_id, $reminder_id, $alert_title, $alert_30_date, $alert_30_time, $alert_type);
    $stmt->execute();
    
    // Insert 15-min alert
    $stmt = $conn->prepare($sql);
    $alert_title = $title . " - 15 mins";
    $alert_type = "15-mins";
    $stmt->bind_param("iissss", $user_id, $reminder_id, $alert_title, $alert_15_date, $alert_15_time, $alert_type);
    $stmt->execute();
    
    // Insert 5-min alert
    $stmt = $conn->prepare($sql);
    $alert_title = $title . " - 5 mins";
    $alert_type = "5-mins";
    $stmt->bind_param("iissss", $user_id, $reminder_id, $alert_title, $alert_5_date, $alert_5_time, $alert_type);
    $stmt->execute();
    
    $stmt->close();
}

$stmt->close();
$conn->close();
?>