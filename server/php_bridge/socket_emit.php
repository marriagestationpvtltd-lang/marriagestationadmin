<?php
/**
 * socket_emit.php — PHP → Node.js Socket.IO bridge helper.
 *
 * Include this file in any PHP endpoint that needs to push a real-time
 * event to connected Flutter clients.
 *
 * Usage:
 *   require_once __DIR__ . '/socket_emit.php';
 *   socketEmit('new_member', ['userId' => $id, 'name' => $name]);
 *   socketEmit('doc_update', ['docId' => $docId, 'status' => 'approved']);
 */

/** Node.js Socket.IO server internal endpoint. */
define('SOCKET_SERVER_URL', 'http://localhost:3001/internal/emit');

/**
 * Internal shared secret — must match INTERNAL_SECRET in the Node.js .env file.
 * Store this in a config file or environment variable in production.
 */
define('SOCKET_INTERNAL_SECRET', getenv('SOCKET_INTERNAL_SECRET') ?: 'change_me_to_a_strong_secret');

/**
 * Emit a Socket.IO event from PHP.
 *
 * @param string      $event  Event name (e.g. 'new_member', 'doc_update').
 * @param array       $data   Associative array of event payload.
 * @param string|null $room   Optional room ID to target.  Null = broadcast all.
 * @return bool               True on success, false on failure.
 */
function socketEmit(string $event, array $data, ?string $room = null): bool
{
    $payload = json_encode([
        'event' => $event,
        'data'  => $data,
        'room'  => $room,
    ]);

    $ch = curl_init(SOCKET_SERVER_URL);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $payload,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 3,          // Fast fire-and-forget
        CURLOPT_HTTPHEADER     => [
            'Content-Type: application/json',
            'X-Internal-Secret: ' . SOCKET_INTERNAL_SECRET,
        ],
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error    = curl_error($ch);
    curl_close($ch);

    if ($error) {
        error_log("[Socket] cURL error for event '$event': $error");
        return false;
    }

    if ($httpCode !== 200) {
        error_log("[Socket] Non-200 response ($httpCode) for event '$event': $response");
        return false;
    }

    return true;
}
