<?php

namespace Inovector\Mixpost\MediaConversions;

use FFMpeg\Coordinate\TimeCode;
use FFMpeg\FFMpeg;
use Illuminate\Support\Facades\File;
use Inovector\Mixpost\Abstracts\Image;
use Inovector\Mixpost\Abstracts\MediaConversion;
use Inovector\Mixpost\Support\ImageResizer;
use Inovector\Mixpost\Support\MediaConversionData;
use Inovector\Mixpost\Support\TemporaryFile;
use Inovector\Mixpost\Util;

class MediaVideoThumbConversion extends MediaConversion
{
    protected float $atSecond = 0;

    public function getEngineName(): string
    {
        return 'VideoThumb';
    }

    public function canPerform(): bool
    {
        return $this->isVideo();
    }

    public function getPath(): string
    {
        return $this->getFilePathWithSuffix('jpg');
    }

    public function atSecond(float $value = 0): static
    {
        $this->atSecond = $value;

        return $this;
    }

    public function handle(): MediaConversionData|null
    {
        if(!Util::isFFmpegInstalled()) {
            return null;
        }

        $temporaryFile = TemporaryFile::make()->fromDisk(
            sourceDisk: $this->getFromDisk(),
            sourceFilepath: $this->getFilepath()
        );

        $thumbFilepath = $this->getFilePathWithSuffix('jpg', $temporaryFile->path());

        // Convert
        $ffmpeg = FFMpeg::create([
            'ffmpeg.binaries' => Util::config('ffmpeg_path'),
            'ffprobe.binaries' => Util::config('ffprobe_path'),
        ]);

        $video = $ffmpeg->open($temporaryFile->path());
        $duration = $ffmpeg->getFFProbe()->format($temporaryFile->path())->get('duration');

        // Ensure $seconds is within valid bounds
        $seconds = ($duration > 0 && $this->atSecond > 0) ? min($this->atSecond, floor($duration)) : 0;

        $frame = $video->frame(TimeCode::fromSeconds($seconds));
        $frame->save($thumbFilepath);

        // Sometimes the frame is not saved, so we save it again with the first frame
        // This is a workaround for the issue
        if ($this->atSecond !== 0 && !File::exists($thumbFilepath)) {
            $frame = $video->frame(TimeCode::fromSeconds(0));
            $frame->save($thumbFilepath);
        }

        // Resize the thumbnail and save it to the destination disk
        ImageResizer::make($thumbFilepath)
            ->disk($this->getToDisk())
            ->path($this->getPath())
            ->resize(Image::MEDIUM_WIDTH, Image::MEDIUM_HEIGHT);

        $temporaryFile->directory()->delete();

        return MediaConversionData::conversion($this);
    }
}
