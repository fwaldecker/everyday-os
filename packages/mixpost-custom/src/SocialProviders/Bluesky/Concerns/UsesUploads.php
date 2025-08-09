<?php

namespace Inovector\Mixpost\SocialProviders\Bluesky\Concerns;

use Inovector\Mixpost\Models\Media;
use Inovector\Mixpost\Support\SocialProviderResponse;
use Inovector\Mixpost\Util;
use Inovector\Mixpost\Support\TemporaryFile;

trait UsesUploads
{
    use UsesOAuthAgent;
    use UsesResponseBuilder;

    /**
     * @see https://docs.bsky.app/docs/api/com-atproto-repo-upload-blob
     */
    public function uploadBlob(Media|TemporaryFile $media): SocialProviderResponse
    {
        $readStream = match (true) {
            $media instanceof Media => $media->readStream(),
            $media instanceof TemporaryFile => ['stream' => $media->readStream(), 'temporaryDirectory' => $media->directory()],
        };

        $mimeType = match (true) {
            $media instanceof Media => $media->mime_type,
            $media instanceof TemporaryFile => $media->mimeType(),
        };

        $response = $this->http()
            ->withBody($readStream['stream'], $mimeType)
            ->post("com.atproto.repo.uploadBlob");

        Util::closeAndDeleteStreamResource($readStream);

        return $this->buildResponse($response);
    }
}
