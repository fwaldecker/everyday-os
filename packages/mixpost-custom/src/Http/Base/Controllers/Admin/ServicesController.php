<?php

namespace Inovector\Mixpost\Http\Base\Controllers\Admin;

use Illuminate\Http\RedirectResponse;
use Illuminate\Routing\Controller;
use Inertia\Inertia;
use Inertia\Response;
use Inovector\Mixpost\Facades\ServiceManager;
use Inovector\Mixpost\Http\Base\Requests\Admin\SaveService;

class ServicesController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Admin/Configuration/Services', [
            'services' => ServiceManager::all()
        ]);
    }

    public function update(SaveService $saveService): RedirectResponse
    {
        $saveService->handle();

        return back();
    }
}
