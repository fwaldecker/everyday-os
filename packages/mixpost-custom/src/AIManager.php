<?php

namespace Inovector\Mixpost;

use Inovector\Mixpost\AIProviders\OpenAI\OpenAIProvider;
use Inovector\Mixpost\Abstracts\AIManager as AIManagerAbstract;

class AIManager extends AIManagerAbstract
{
    protected array $cacheProviders = [];

    public function registeredProviders(): array
    {
        return [
            OpenAIProvider::class
        ];
    }

    public function providers(): array
    {
        if (!empty($this->cacheProviders)) {
            return $this->cacheProviders;
        }

        return $this->cacheProviders = $this->registeredProviders();
    }
}
