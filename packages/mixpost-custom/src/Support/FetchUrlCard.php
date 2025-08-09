<?php

namespace Inovector\Mixpost\Support;

use Exception;
use Illuminate\Support\Facades\Http;
use DOMDocument;
use DOMXPath;
use Closure;

class FetchUrlCard
{
    public function __invoke(string $url): array
    {
        $data = [
            'url' => $url,
            'title' => '',
            'description' => '',
            'image' => ''
        ];

        try {
            $response = Http::timeout(10)->get($url);

            $doc = new DOMDocument();
            @$doc->loadHTML($response->body());

            $xpath = new DOMXPath($doc);

            $data['title'] = $this->getAttributeContent($xpath, 'property', 'og:title', function () use ($xpath) {
                return $xpath->query('//title')->item(0)?->nodeValue;
            });
            $data['description'] = $this->getAttributeContent($xpath, 'property', 'og:description', '//meta[@name="description"]');
            $data['image'] = $this->getAttributeContent($xpath, 'property', 'og:image', '//img');

            $twitterData = [
                'url' => $this->getAttributeContent($xpath, 'name', 'twitter:url'),
                'title' => $this->getAttributeContent($xpath, 'name', 'twitter:title'),
                'description' => $this->getAttributeContent($xpath, 'name', 'twitter:description'),
                'image' => $this->getAttributeContent($xpath, 'name', 'twitter:image'),
            ];

        } catch (Exception $e) {
            $twitterData = $data;
        }

        return [
            'default' => $data,
            'twitter' => $twitterData
        ];
    }

    private function getAttributeContent($xpath, $attribute, $attributeValue, Closure|string $fallbackQuery = '')
    {
        $node = $xpath->query('//meta[@' . $attribute . '="' . $attributeValue . '"]')->item(0);

        if ($node) {
            return $node->getAttribute('content');
        } elseif ($fallbackQuery) {
            if (is_callable($fallbackQuery)) {
                return $fallbackQuery();
            }

            $fallbackNode = $xpath->query($fallbackQuery)->item(0);
            return $fallbackNode ? $fallbackNode->getAttribute('content') : '';
        }

        return '';
    }
}
