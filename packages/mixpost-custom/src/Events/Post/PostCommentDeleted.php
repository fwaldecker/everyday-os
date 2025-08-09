<?php

namespace Inovector\Mixpost\Events\Post;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Inovector\Mixpost\Contracts\QueueWorkspaceAware;
use Inovector\Mixpost\Contracts\WebhookEvent;

class PostCommentDeleted implements ShouldBroadcastNow, QueueWorkspaceAware, WebhookEvent
{
    use Dispatchable, SerializesModels, InteractsWithSockets;

    public string $postUuid;
    public string $activityUuid;

    public function __construct(string $postUuid, string $activityUuid)
    {
        $this->postUuid = $postUuid;
        $this->activityUuid = $activityUuid;
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel('mixpost_posts.' . $this->postUuid);
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->activityUuid,
        ];
    }

    public static function name(): string
    {
        return 'post.comment.deleted';
    }

    public static function nameLocalized(): string
    {
        return __('mixpost::webhook.event.post.comment.deleted');
    }

    public function payload(): array
    {
        return [
            'post_uuid' => $this->postUuid,
            'activity_uuid' => $this->activityUuid,
        ];
    }
}
