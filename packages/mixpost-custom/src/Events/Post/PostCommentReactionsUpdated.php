<?php

namespace Inovector\Mixpost\Events\Post;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Inovector\Mixpost\Contracts\QueueWorkspaceAware;
use Inovector\Mixpost\Contracts\WebhookEvent;
use Inovector\Mixpost\Http\Base\Resources\PostActivityResource;
use Inovector\Mixpost\Models\PostActivity;

class PostCommentReactionsUpdated implements ShouldBroadcast, QueueWorkspaceAware, WebhookEvent
{
    use Dispatchable, SerializesModels, InteractsWithSockets;

    public $deleteWhenMissingModels = true;

    public PostActivity $activity;

    public function __construct(PostActivity $activity)
    {
        $this->activity = $activity;
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('mixpost_posts.' . $this->activity->post?->uuid);
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->activity->uuid,
            'is_child' => (bool)$this->activity->parent_id,
            'reactions' => $this->activity->load(['reactions.user'])->groupedReactions()
        ];
    }

    public static function name(): string
    {
        return 'post.comment.reactions.updated';
    }

    public static function nameLocalized(): string
    {
        return __('mixpost::webhook.event.post.comment.reactions.updated');
    }

    public function payload(): array
    {
        $this->activity->load('post', 'post.accounts', 'post.versions', 'post.tags', 'reactions.user');
        
        return [
            'activity' => (new PostActivityResource($this->activity))->resolve(),
            'post_id' => $this->activity->post_id,
            'reactions' => $this->activity->groupedReactions(),
            'platform' => $this->activity->data['platform'] ?? null,
        ];
    }
}
