<?php

use Illuminate\Support\Facades\Route;

use Inovector\Mixpost\Features;
use Inovector\Mixpost\Util;

if (Features::isApiAccessTokenEnabled()) {
    Route::prefix(Util::corePath() . '/api')
        ->middleware(Util::config('middlewares')['api'])
        ->name('mixpost.api.')
        ->group(function () {
            require __DIR__ . '/includes/workspace.php';
        });
}
