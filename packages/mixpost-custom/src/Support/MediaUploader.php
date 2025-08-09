<?php

namespace Inovector\Mixpost\Support;

use Illuminate\Contracts\Filesystem\Filesystem;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Storage;
use Inovector\Mixpost\Abstracts\Image;
use Inovector\Mixpost\Concerns\UsesMimeType;
use Inovector\Mixpost\Models\Media;
use Inovector\Mixpost\Contracts\MediaConversion;
use Inovector\Mixpost\Util;
use League\Flysystem\Local\LocalFilesystemAdapter;

class MediaUploader
{
    use UsesMimeType;

    protected UploadedFile $file;

    protected string $disk;

    protected string $path = '';

    protected ?array $data = null;

    protected int $width;

    protected int $height;

    protected array $conversions;

    public function __construct(UploadedFile $file)
    {
        $this->setFile($file);

        $this->disk(Util::config('disk'));

        $this->width = Image::LARGE_WIDTH;
        $this->height = Image::LARGE_HEIGHT;
    }

    public static function fromFile(UploadedFile $file): static
    {
        return new static($file);
    }

    public function setFile(UploadedFile $file): static
    {
        $this->file = $file;

        return $this;
    }

    public function disk(string $name): static
    {
        $this->disk = $name;

        return $this;
    }

    public function path(string $path): static
    {
        $this->path = $path;

        return $this;
    }

    public function data(array $array): static
    {
        $this->data = !empty($array) ? $array : null;

        return $this;
    }

    public function width(int $width): static
    {
        $this->width = $width;

        return $this;
    }

    public function height(int $height): static
    {
        $this->height = $height;

        return $this;
    }

    public function conversions(array $array): static
    {
        $this->conversions = $array;

        return $this;
    }

    public function upload(): array
    {
        $mimeType = $this->file->getMimeType();
        $filesystem = $this->filesystem();

        // Determine upload path
        $filePath = $this->isImage($mimeType) && !$this->isGifImage($mimeType)
            ? $this->uploadImage()
            : $filesystem->putFile($this->path, $this->file, 'public');

        if (!$filePath) {
            throw new \Exception("The file was not uploaded. Check your $this->disk driver configuration.");
        }

        $size = $filesystem->size($filePath);
        $conversions = $this->performConversions($filePath);
        $totalSize = $size + collect($conversions)->sum('size');

        return [
            'name' => $this->file->getClientOriginalName(),
            'mime_type' => $mimeType,
            'size' => $size,
            'size_total' => $totalSize,
            'disk' => $this->disk,
            'is_local_driver' => $filesystem->getAdapter() instanceof LocalFilesystemAdapter,
            'path' => $filePath,
            'url' => $filesystem->url($filePath),
            'conversions' => $conversions,
            'data' => $this->data ?: null,
        ];
    }

    public function uploadAndInsert()
    {
        $data = Arr::only($this->upload(), ['name', 'mime_type', 'size', 'size_total', 'disk', 'path', 'conversions', 'data']);

        if (!(  isset($this->data['adobe_express_doc_id'])
                &&
                $media = Media::whereJsonContains('data->adobe_express_doc_id', $this->data['adobe_express_doc_id'])->first())) {
            return Media::create($data);
        }

        $media->deleteFiles();
        $media->update($data);

        return $media->refresh();
    }

    protected function performConversions(string $filepath): array
    {
        if (empty($this->conversions)) {
            return [];
        }

        return collect($this->conversions)->map(function ($conversion) use ($filepath) {
            if (!$conversion instanceof MediaConversion) {
                throw new \Exception('The conversion must be an instance of MediaConversion');
            }

            $perform = $conversion->filepath($filepath)->fromDisk($this->disk)->perform();

            if (!$perform) {
                return null;
            }

            return $perform->get();
        })->filter()->values()->toArray();
    }

    protected function uploadImage(): string
    {
        $image = ImageResizer::make($this->file);

        $image->disk($this->disk)
            ->path($this->path)
            ->resize(Image::LARGE_WIDTH);

        return $image->getDestinationFilePath();
    }

    protected function filesystem(): Filesystem
    {
        return Storage::disk($this->disk);
    }
}
