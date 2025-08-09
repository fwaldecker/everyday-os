<?php

namespace Inovector\Mixpost\Concerns;

use Intervention\Image\Drivers\Gd\Driver;
use Intervention\Image\ImageManager;

trait UsesImageManager
{
    public function imageManager(): ImageManager
    {
        return new ImageManager(new Driver());
    }
}
