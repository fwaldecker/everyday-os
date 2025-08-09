<?php

namespace Inovector\Mixpost\Support;

use Illuminate\Support\Facades\File as FileFacade;
use Inovector\Mixpost\Concerns\Makeable;
use Spatie\TemporaryDirectory\TemporaryDirectory;
use LogicException;
use RuntimeException;

final class TemporaryFile
{
    use Makeable;

    private TemporaryDirectory $directory;
    private string $path;

    public function __construct()
    {
        $this->directory = MediaTemporaryDirectory::create();
    }

    public function fromUrl(string $url, ?string $customFilename = null): self
    {
        $response = File::fetchUrl($url);

        if (!$response->successful()) {
            throw new RuntimeException('Failed to download file from URL: ' . $url);
        }

        $fileNameFromResponse = File::getFilenameFromHttpResponse($response);
        $extension = pathinfo($fileNameFromResponse, PATHINFO_EXTENSION);

        $this->path = $this->directory->path($customFilename ? $customFilename . '.' . $extension : $fileNameFromResponse);

        FileFacade::put($this->path, $response->body());

        return $this;
    }

    public function fromDisk(string $sourceDisk, string $sourceFilepath): self
    {
        $this->path = $this->directory->path($sourceFilepath);

        MediaFilesystem::copyFromDisk(
            sourceDisk: $sourceDisk,
            sourceFilepath: $sourceFilepath,
            destinationFilePath: $this->path
        );

        return $this;
    }

    public function path(): string
    {
        return $this->path;
    }

    public function contents(): string
    {
        $this->ensureFilePathExists();

        return FileFacade::get($this->path);
    }

    /**
     * @return bool|resource
     */
    public function readStream()
    {
        $this->ensureFilePathExists();

        return fopen($this->path, 'r');
    }

    public function delete(): bool
    {
        $this->ensureFilePathExists();

        return FileFacade::delete($this->path);
    }

    public function directory(): TemporaryDirectory
    {
        return $this->directory;
    }

    public function basename(): string
    {
        $this->ensureFilePathExists();

        return FileFacade::basename($this->path);
    }

    public function name(): string
    {
        $this->ensureFilePathExists();

        return FileFacade::name($this->path);
    }

    public function extension(): string
    {
        $this->ensureFilePathExists();

        return FileFacade::extension($this->path);
    }

    public function mimeType(): false|string
    {
        $this->ensureFilePathExists();

        return FileFacade::mimeType($this->path);
    }

    private function ensureFilePathExists(): void
    {
        if (!$this->path) {
            throw new LogicException('No file path set.');
        }
    }
}
