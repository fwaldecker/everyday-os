<?php

require __DIR__.'/../../vendor/autoload.php';

use Illuminate\Http\Request;

// Create a test request with JSON data
$request = Request::create(
    '/mixpost/api/test',
    'POST',
    [], // Query parameters
    [], // Cookies
    [], // Files
    [
        'CONTENT_TYPE' => 'application/json',
        'HTTP_ACCEPT' => 'application/json',
    ],
    json_encode(['text' => 'Test comment', 'user_id' => 2])
);

echo "Request all(): ";
print_r($request->all());
echo "\nRequest json(): ";
print_r($request->json()->all());
echo "\nRequest input('text'): " . $request->input('text') . "\n";