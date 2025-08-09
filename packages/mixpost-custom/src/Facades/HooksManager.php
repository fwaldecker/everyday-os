<?php

namespace Inovector\Mixpost\Facades;

use Illuminate\Support\Facades\Facade;

/**
 * @method static void addAction(string $hook, callable $callback, int $priority = 10)
 * @method static void doAction(string $hook, ...$args)
 * @method static void removeAction(string $hook, callable $callback, int $priority = 10)
 *
 * @see \Inovector\Mixpost\HooksManager
 */
class HooksManager extends Facade
{
    protected static function getFacadeAccessor()
    {
        return 'MixpostHooksManager';
    }
}
