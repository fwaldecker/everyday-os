<?php

namespace Inovector\Mixpost\SocialProviders\Bluesky\Concerns;

use Inovector\Mixpost\Support\SocialProviderResponse;

trait ManagesMetrics
{
    use UsesValues;
    use UsesResponseBuilder;

    public function getAccountMetrics(): SocialProviderResponse
    {
        $response = $this->http()->get("app.bsky.actor.getProfile", [
            'actor' => $this->getDid(),
        ]);

        return $this->buildResponse($response, function ($data) {
            return [
                'followers' => $data['followersCount'],
            ];
        });
    }
}
