<?php
/**
 * Uniting Technology BV — Contact Form Handler
 * SMTP: send.one.com:465
 * From: info@uniting-tech.com
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: https://www.uniting-tech.com');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// ── Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'msg' => 'Method not allowed']);
    exit;
}

// ── Config — fill in your email password
define('SMTP_HOST',     'send.one.com');
define('SMTP_PORT',     465);
define('SMTP_USER',     'info@uniting-tech.com');
define('SMTP_PASS',     'YOUR_EMAIL_PASSWORD_HERE'); // ← cambiar
define('MAIL_FROM',     'info@uniting-tech.com');
define('MAIL_FROM_NAME','Uniting Technology BV');
define('MAIL_TO',       'info@uniting-tech.com');
define('MAIL_BCC',      'briefing@uniting-tech.com'); // opcional

// ── Get + sanitize input
function clean($v) {
    return htmlspecialchars(strip_tags(trim($v ?? '')), ENT_QUOTES, 'UTF-8');
}

$name         = clean($_POST['name']         ?? '');
$organization = clean($_POST['organization'] ?? '');
$email        = filter_var(trim($_POST['email'] ?? ''), FILTER_SANITIZE_EMAIL);
$industry     = clean($_POST['industry']     ?? '');
$service      = clean($_POST['service']      ?? '');
$message      = clean($_POST['message']      ?? '');
$lang         = clean($_POST['lang']         ?? 'en');

// ── Validate
if (!$name || !$email || !filter_var($email, FILTER_VALIDATE_EMAIL) || !$message) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'msg' => 'Missing required fields']);
    exit;
}

// ── Build email body (internal notification)
$subject_internal = "[UT Lead] $name — $organization";
$body_internal = "
NEW STRATEGIC BRIEFING REQUEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name:         $name
Organization: $organization
Email:        $email
Industry:     $industry
Service:      $service
Language:     $lang
Timestamp:    " . date('Y-m-d H:i:s T') . "

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MESSAGE:

$message

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source: www.uniting-tech.com/contact
";

// ── Auto-reply to lead
$replies = [
    'es' => [
        'subject' => 'Uniting Technology — Hemos recibido su solicitud',
        'body'    => "Estimado/a $name,\n\nGracias por contactar con Uniting Technology BV.\n\nHemos recibido su solicitud de briefing estratégico y nuestro equipo le responderá desde esta misma dirección dentro de 48 horas hábiles.\n\nMientras tanto, puede explorar nuestro ecosistema de productos en www.uniting-tech.com.\n\nAtentamente,\n\nUniting Technology BV\nGhent, Belgium\ninfo@uniting-tech.com\n+32 499 817 670\n\n—\nThe Future. Engineered."
    ],
    'pt' => [
        'subject' => 'Uniting Technology — Recebemos a sua solicitação',
        'body'    => "Prezado/a $name,\n\nObrigado por contatar a Uniting Technology BV.\n\nRecebemos sua solicitação de briefing estratégico e nossa equipe responderá a partir deste endereço dentro de 48 horas úteis.\n\nAtenciosamente,\n\nUniting Technology BV\nGhent, Belgium\ninfo@uniting-tech.com\n+32 499 817 670\n\n—\nThe Future. Engineered."
    ],
    'en' => [
        'subject' => 'Uniting Technology — We have received your request',
        'body'    => "Dear $name,\n\nThank you for contacting Uniting Technology BV.\n\nWe have received your strategic briefing request and our team will reply from this address within 48 business hours.\n\nIn the meantime, you may explore our ecosystem at www.uniting-tech.com.\n\nBest regards,\n\nUniting Technology BV\nGhent, Belgium\ninfo@uniting-tech.com\n+32 499 817 670\n\n—\nThe Future. Engineered."
    ]
];

$reply = $replies[$lang] ?? $replies['en'];

// ── Send via SMTP (using PHP socket — no library needed)
function smtp_send($host, $port, $user, $pass, $from, $from_name, $to, $subject, $body, $bcc = '') {
    $socket = fsockopen("ssl://$host", $port, $errno, $errstr, 10);
    if (!$socket) return false;

    $read = function() use ($socket) { return fgets($socket, 515); };
    $write = function($cmd) use ($socket) { fwrite($socket, "$cmd\r\n"); };

    $read(); // 220 greeting
    $write("EHLO " . php_uname('n'));
    while ($line = $read()) { if (substr($line, 3, 1) === ' ') break; }

    $write("AUTH LOGIN");
    $read();
    $write(base64_encode($user));
    $read();
    $write(base64_encode($pass));
    $auth = $read();
    if (strpos($auth, '235') === false) { fclose($socket); return false; }

    $write("MAIL FROM:<$from>");
    $read();
    $write("RCPT TO:<$to>");
    $read();
    if ($bcc) { $write("RCPT TO:<$bcc>"); $read(); }
    $write("DATA");
    $read();

    $headers  = "From: =?UTF-8?B?" . base64_encode($from_name) . "?= <$from>\r\n";
    $headers .= "To: $to\r\n";
    $headers .= "Subject: =?UTF-8?B?" . base64_encode($subject) . "?=\r\n";
    $headers .= "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $headers .= "Content-Transfer-Encoding: base64\r\n";
    $headers .= "Date: " . date('r') . "\r\n";
    $headers .= "X-Mailer: UT-Mailer/1.0\r\n";

    $write($headers . "\r\n" . chunk_split(base64_encode($body)) . "\r\n.");
    $sent = $read();
    $write("QUIT");
    fclose($socket);
    return strpos($sent, '250') !== false;
}

// ── Execute sends
$ok1 = smtp_send(SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS,
    MAIL_FROM, MAIL_FROM_NAME, MAIL_TO,
    $subject_internal, $body_internal, MAIL_BCC);

$ok2 = smtp_send(SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS,
    MAIL_FROM, MAIL_FROM_NAME, $email,
    $reply['subject'], $reply['body']);

// ── Log to file (optional, remove if not needed)
$log_line = date('Y-m-d H:i:s') . " | $email | $organization | $industry | ok1=$ok1 ok2=$ok2\n";
file_put_contents(__DIR__ . '/leads.log', $log_line, FILE_APPEND | LOCK_EX);

// ── Response
if ($ok1 || $ok2) {
    echo json_encode(['ok' => true, 'msg' => 'Sent']);
} else {
    http_response_code(500);
    echo json_encode(['ok' => false, 'msg' => 'SMTP error — contact info@uniting-tech.com']);
}
