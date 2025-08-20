<?php

// Test script to diagnose API comment posting issue

$workspaceUuid = 'dd7477ef-bcd2-45dd-8f2e-14e790fdd2e2';
$postUuid = '044cf196-632b-458c-aedf-c648f25a5223';
$bearerToken = 'YwNO7dcJiIs7o0r9hwgqg8HoamYjIZoh0pLmpz8y67681cb9';

$url = "http://localhost:80/mixpost/api/{$workspaceUuid}/posts/{$postUuid}/comments";

$data = json_encode([
    'text' => 'Test comment from PHP script',
    'user_id' => 2
]);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $bearerToken,
    'Content-Type: application/json',
    'Accept: application/json',
    'Content-Length: ' . strlen($data)
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n";
echo "Response: $response\n";

// Also try with form data
echo "\n--- Testing with form data ---\n";
$ch2 = curl_init($url);
curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch2, CURLOPT_POST, true);
curl_setopt($ch2, CURLOPT_POSTFIELDS, http_build_query([
    'text' => 'Test comment from form data',
    'user_id' => 2
]));
curl_setopt($ch2, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $bearerToken,
    'Accept: application/json',
]);

$response2 = curl_exec($ch2);
$httpCode2 = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
curl_close($ch2);

echo "HTTP Status: $httpCode2\n";
echo "Response: $response2\n";