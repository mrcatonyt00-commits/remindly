<?php
// Set timezone to match your local time
date_default_timezone_set('Asia/Manila'); // CHANGE THIS to your timezone
// Other common timezones:
// 'America/New_York', 'America/Los_Angeles', 'Europe/London', 'Asia/Tokyo', etc.

// Email Configuration
define('MAIL_HOST', 'smtp.gmail.com');
define('MAIL_PORT', 587);
define('MAIL_USERNAME', 'kyleperezgomez11@gmail.com');
define('MAIL_PASSWORD', 'heav fpps ilon qswj');
define('MAIL_FROM_EMAIL', 'kyleperezgomez11@gmail.com');
define('MAIL_FROM_NAME', 'Remindly');

// Database Configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'remindly');
define('DB_USER', 'root');
define('DB_PASSWORD', '');

// Application URL
define('APP_URL', 'http://192.168.100.42/remindly_api');

// Verification link
define('VERIFY_LINK', APP_URL . '/verify.php?token=');
?>