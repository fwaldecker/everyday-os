<?php

namespace Inovector\Mixpost\Http\Api\Controllers\Workspace\Post;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Inovector\Mixpost\Http\Base\Resources\PostActivityResource;
use Inovector\Mixpost\Models\Post;
use Inovector\Mixpost\Concerns\UsesUserModel;

class PostCommentsController extends Controller
{
    use UsesUserModel;

    /**
     * Store a new comment on a post
     * 
     * @param Request $request
     * @return PostActivityResource|\Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'text' => ['required', 'string', 'min:1'],
            'user_id' => ['nullable', 'integer', 'exists:' . (new (self::getUserClass()))->getTable() . ',id'],
            'parent_id' => ['nullable', 'string'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $post = Post::firstOrFailByUuid($request->route('post'));

        // Use provided user_id or fall back to authenticated user
        $userId = $request->input('user_id', Auth::id());
        
        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'User ID is required when not authenticated'
            ], 401);
        }

        // Handle parent comment if replying
        $parentActivity = null;
        if ($request->has('parent_id')) {
            $parentActivity = $post->activities()
                ->where('uuid', $request->input('parent_id'))
                ->first();
            
            if (!$parentActivity || !$parentActivity->isComment()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent comment not found'
                ], 404);
            }
        }

        // Create the comment
        $activity = $post->storeComment(
            user: $userId,
            text: $request->input('text'),
            parent: $parentActivity
        );

        $activity->load('user', 'reactions.user');

        return new PostActivityResource($activity);
    }

    /**
     * Get comments for a post
     * 
     * @param Request $request
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     */
    public function index(Request $request)
    {
        $post = Post::firstOrFailByUuid($request->route('post'));

        $comments = $post->activities()
            ->whereNull('parent_id')
            ->where('type', 'comment')
            ->with(['user', 'reactions.user'])
            ->withCount('children')
            ->latest()
            ->paginate(20);

        return PostActivityResource::collection($comments);
    }
}