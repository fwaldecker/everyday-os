<?php

namespace Inovector\Mixpost\Support;

use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class MediaFilesystem
{
    public static function copyFromDisk(string $sourceDisk, string $sourceFilepath, string $destinationFilePath): bool|int
    {
        $stream = self::getStream($sourceDisk, $sourceFilepath);

        try {
            $result = File::put($destinationFilePath, $stream);
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        return $result;
    }

    public static function copyToDisk(string $destinationDisk, string $destinationFilePath, string $sourceFilePath): bool
    {
        if (!File::exists($sourceFilePath)) {
            throw new RuntimeException("Source file does not exist: $sourceFilePath");
        }

        return Storage::disk($destinationDisk)->put($destinationFilePath, File::get($sourceFilePath), 'public');
    }

    protected static function getStream(string $disk, string $filepath)
    {
        return Storage::disk($disk)->readStream($filepath);
    }
}
