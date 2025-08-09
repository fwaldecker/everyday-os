<?php

namespace Inovector\Mixpost\SocialProviders\Mastodon;

use Illuminate\Http\Request;
use Inovector\Mixpost\Abstracts\SocialProvider;
use Inovector\Mixpost\Contracts\AccountResource;
use Inovector\Mixpost\SocialProviders\Mastodon\Concerns\ManagesConfig;
use Inovector\Mixpost\SocialProviders\Mastodon\Concerns\ManagesOAuth;
use Inovector\Mixpost\SocialProviders\Mastodon\Concerns\ManagesRateLimit;
use Inovector\Mixpost\SocialProviders\Mastodon\Concerns\ManagesResources;
use Inovector\Mixpost\SocialProviders\Mastodon\Support\MastodonPostOptions;
use Inovector\Mixpost\Contracts\SocialProviderPostOptions;
use Inovector\Mixpost\Support\SocialProviderPostConfigs;
use Inovector\Mixpost\Util;

class MastodonProvider extends SocialProvider
{
    use ManagesConfig;
    use ManagesRateLimit;
    use ManagesOAuth;
    use ManagesResources;

    public array $callbackResponseKeys = ['code'];

    protected string $apiVersion = 'v1';
    protected string $serverUrl;

    public function __construct(Request $request, string $clientId, string $clientSecret, string $redirectUrl, array $values = [])
    {
        $this->serverUrl = "https://{$values['data']['server']}";

        parent::__construct($request, $clientId, $clientSecret, $redirectUrl, $values);
    }

    public static function service(): string
    {
        return 'mastodon';
    }

    public static function postConfigs(): SocialProviderPostConfigs
    {
        return SocialProviderPostConfigs::make()
            ->simultaneousPosting(Util::config('social_provider_options.mastodon.simultaneous_posting_on_multiple_accounts'))
            ->minTextChar(1)
            ->maxTextChar(Util::config('social_provider_options.mastodon.post_character_limit'))
            ->minPhotos(1)
            ->minVideos(1)
            ->minGifs(1)
            ->maxPhotos(Util::config('social_provider_options.mastodon.media_limit.photos'))
            ->maxVideos(Util::config('social_provider_options.mastodon.media_limit.videos'))
            ->maxGifs(Util::config('social_provider_options.mastodon.media_limit.gifs'))
            ->allowMixingMediaTypes(Util::config('social_provider_options.mastodon.allow_mixing'));
    }

    public static function postOptions(): SocialProviderPostOptions
    {
        return new MastodonPostOptions();
    }

    public static function externalPostUrl(AccountResource $accountResource): string
    {
        $server = $accountResource->data['server'] ?? null;

        if (!$server) {
            return '';
        }

        return "https://$server/@$accountResource->username/{$accountResource->pivot->provider_post_id}";
    }

    public static function externalAccountUrl(AccountResource $accountResource): string
    {
        $server = $accountResource->data['server'] ?? null;

        if (!$server) {
            return '';
        }

        return "https://" . $server . '/@' . $accountResource->username;
    }

    public static function mapErrorMessage(string $key): string
    {
        return match ($key) {
            'access_token_expired' => __('mixpost::account.access_token_expired'),
            'upload_failed' => __('mixpost::service.mastodon.upload_failed'),
            default => $key
        };
    }

    public static function supportPostDeletion(): bool|array
    {
        return true;
    }
}
