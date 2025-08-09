<?php

namespace Inovector\Mixpost\Http\Api\Controllers\Workspace;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Routing\Controller;
use Inovector\Mixpost\Http\Api\Requests\Workspace\DeleteMedia;
use Inovector\Mixpost\Http\Api\Requests\Workspace\UpdateMedia;
use Inovector\Mixpost\Http\Api\Resources\MediaResource;
use Inovector\Mixpost\Models\Media;

class MediaController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return MediaResource::collection(
            Media::latest('created_at')->paginate(20)
        );
    }

    public function show(Request $request): MediaResource
    {
        return new MediaResource(
            Media::firstOrFailByUuid($request->route('media'))
        );
    }

    public function update(UpdateMedia $updateMedia): JsonResponse
    {
        return response()->json([
            'success' => (bool)$updateMedia->handle(),
        ]);
    }

    public function destroy(DeleteMedia $deleteMediaFiles): JsonResponse
    {
        $deleteMediaFiles->handle();

        return response()->json([
            'success' => true
        ]);
    }
}
