<?php

namespace Inovector\Mixpost\SocialProviders\Bluesky\Concerns;

use Inovector\Mixpost\Enums\SocialProviderContentType;
use Inovector\Mixpost\Support\SocialProviderPostConfigs;

trait ManagesConfig
{
    public static function contentType(): SocialProviderContentType
    {
        return SocialProviderContentType::THREAD;
    }

    public static function postConfigs(): SocialProviderPostConfigs
    {
        return SocialProviderPostConfigs::make()
            ->simultaneousPosting(true)
            ->minPhotos(0)
            ->minVideos(0)
            ->minGifs(0)
            ->maxTextChar(300)
            ->maxPhotos(4)
            ->maxVideos(1)
            ->maxGifs(1)
            ->allowMixingMediaTypes(false);
    }
}
