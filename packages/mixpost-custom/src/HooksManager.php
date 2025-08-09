<?php

namespace Inovector\Mixpost;

class HooksManager
{
    protected array $actions = [];

    public function addAction(string $hook, callable $callback, int $priority = 10): void
    {
        $this->actions[$hook][$priority][] = $callback;
        ksort($this->actions[$hook]);
    }

    public function doAction(string $hook, ...$args): void
    {
        if (!isset($this->actions[$hook])) {
            return;
        }

        foreach ($this->actions[$hook] as $priority => $callbacks) {
            foreach ($callbacks as $callback) {
                call_user_func_array($callback, $args);
            }
        }
    }

    public function removeAction(string $hook, callable $callback, int $priority = 10): void
    {
        if (isset($this->actions[$hook][$priority])) {
            foreach ($this->actions[$hook][$priority] as $key => $registeredCallback) {
                if ($registeredCallback === $callback) {
                    unset($this->actions[$hook][$priority][$key]);
                }
            }

            if (empty($this->actions[$hook][$priority])) {
                unset($this->actions[$hook][$priority]);
            }

            if (empty($this->actions[$hook])) {
                unset($this->actions[$hook]);
            }
        }
    }
}
