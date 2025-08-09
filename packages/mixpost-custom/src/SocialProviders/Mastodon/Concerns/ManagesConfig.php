<?php

namespace Inovector\Mixpost\SocialProviders\Mastodon\Concerns;

use Inovector\Mixpost\Enums\SocialProviderContentType;

trait ManagesConfig
{
    public static function contentType(): SocialProviderContentType
    {
        return SocialProviderContentType::THREAD;
    }
}
