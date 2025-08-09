<?php

namespace Inovector\Mixpost\SocialProviders\Bluesky;

use Illuminate\Support\Facades\Http;

class Helpers
{
    public static function parseFacets(string $text, string $server): array
    {
        $facets = [];

        foreach (self::parseMentions($text) as $mention) {
            $response = Http::timeout(5)->get("$server/xrpc/com.atproto.identity.resolveHandle", [
                'handle' => $mention['handle'],
            ]);

            if (!$response->successful()) {
                continue;
            }

            if (!$did = $response->json('did')) {
                continue;
            }

            $facets[] = [
                'index' => [
                    'byteStart' => $mention['start'],
                    'byteEnd' => $mention['end'],
                ],
                'features' => [['$type' => 'app.bsky.richtext.facet#mention', 'did' => $did]],
            ];
        }

        foreach (self::parseUrls($text) as $url) {
            $facets[] = [
                'index' => [
                    'byteStart' => $url['start'],
                    'byteEnd' => $url['end'],
                ],
                'features' => [[
                    '$type' => 'app.bsky.richtext.facet#link',
                    'uri' => $url['url'],
                ]],
            ];
        }

        foreach (self::parseHashtags($text) as $hashtag) {
            $facets[] = [
                'index' => [
                    'byteStart' => $hashtag['start'],
                    'byteEnd' => $hashtag['end'],
                ],
                'features' => [[
                    '$type' => 'app.bsky.richtext.facet#tag',
                    'tag' => $hashtag['tag'],
                ]],
            ];
        }

        return $facets;
    }

    public static function parseMentions(string $text): array
    {
        $spans = [];
        $mentionRegex = '/[\$|\W](@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)/u';

        if (preg_match_all($mentionRegex, $text, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[1] as $match) {
                $spans[] = [
                    'start' => $match[1],
                    'end' => $match[1] + strlen($match[0]),
                    'handle' => substr($match[0], 1),
                ];
            }
        }

        return $spans;
    }

    public static function parseUrls(string $text): array
    {
        $spans = [];
        $urlRegex = '/[\$|\W](https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/=-]*[-a-zA-Z0-9@%_\+~#\/=-])?)/u';

        if (preg_match_all($urlRegex, $text, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[1] as $match) {
                $spans[] = [
                    'start' => $match[1],
                    'end' => $match[1] + strlen($match[0]),
                    'url' => $match[0],
                ];
            }
        }

        return $spans;
    }

    public static function parseHashtags(string $text): array
    {
        $spans = [];
        $hashtagRegex = '/(?:^|\s)(#[^\d\s]\S*)(?=\s|$)/u';

        if (preg_match_all($hashtagRegex, $text, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[1] as $match) {
                $tag = trim($match[0]);
                $tag = preg_replace('/\p{P}+$/u', '', $tag); // Strip trailing punctuation

                if (mb_strlen($tag) > 66) {
                    continue; // Max length check (inclusive of #, max 64 chars)
                }

                $spans[] = [
                    'start' => $match[1],
                    'end' => $match[1] + mb_strlen($tag, 'UTF-8'),
                    'tag' => ltrim($tag, '#'),
                ];
            }
        }

        return $spans;
    }
}
