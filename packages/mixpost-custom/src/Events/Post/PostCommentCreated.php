<?php

namespace Inovector\Mixpost\Events\Post;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Inovector\Mixpost\Contracts\WebhookEvent;
use Inovector\Mixpost\Http\Base\Resources\PostActivityResource;
use Inovector\Mixpost\Models\PostActivity;

class PostCommentCreated implements WebhookEvent
{
    use Dispatchable, SerializesModels;

    public PostActivity $activity;

    public function __construct(PostActivity $activity)
    {
        $this->activity = $activity;
    }

    public static function name(): string
    {
        return 'post.comment.created';
    }

    public static function nameLocalized(): string
    {
        return __('mixpost::webhook.event.post.comment.created');
    }

    public function payload(): array
    {
        $this->activity->load('user', 'post', 'post.accounts', 'post.versions', 'post.tags');
        
        return [
            'comment' => (new PostActivityResource($this->activity))->resolve(),
            'post_id' => $this->activity->post_id,
            'post_uuid' => $this->activity->post?->uuid,
            'workspace_id' => $this->activity->post?->workspace_id,
            'user' => [
                'id' => $this->activity->user?->id,
                'name' => $this->activity->user?->name,
                'email' => $this->activity->user?->email,
            ],
            'text' => $this->activity->text,
            'parent_id' => $this->activity->parent_id,
            'is_reply' => (bool) $this->activity->parent_id,
        ];
    }
}