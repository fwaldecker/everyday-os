<?php

namespace Inovector\Mixpost\Http\Base\Requests\Workspace;

use Exception;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\File;
use Inovector\Mixpost\Abstracts\Image;
use Inovector\Mixpost\Concerns\UsesMediaPath;
use Inovector\Mixpost\Events\Media\UploadingMediaFile;
use Inovector\Mixpost\MediaConversions\MediaImageResizerConversion;
use Inovector\Mixpost\MediaConversions\MediaVideoThumbConversion;
use Inovector\Mixpost\Models\Media;
use Inovector\Mixpost\Support\MediaUploader;
use Inovector\Mixpost\Util;
use Inovector\Mixpost\Support\File as FileSupport;

class MediaUploadFile extends FormRequest
{
    use UsesMediaPath;

    public function rules(): array
    {
        return [
            'file' => ['required', function ($attribute, $value, $fail) {
                if ($this->hasFile('file')) {
                        $rules = File::types($this->allowedTypes())->max($this->max());
                        validator(['file' => $value], ['file' => [$rules]])->validate();
                }
                else if (!filter_var($value, FILTER_VALIDATE_URL)) {
                    $fail('The file must be an uploaded file or a valid file URL.');
                }
            }],
            'adobe_express_doc_id' => ['string', 'max:255'],
            'file_name' => ['string', 'max:255'],
            // TODO: Need to refactor
//            'integration' => ['required', 'in:default, adobe_express'],
//            'integration_data' => ['sometimes', 'array'],
            'alt_text' => ['string', 'max:255', 'nullable']
        ];
    }

    private function max(): int
    {
        $max = 0;

        if (!$this->file('file')) {
            return $max;
        }

        if ($this->isImage()) {
            $max = config('mixpost.max_file_size.image');
        }

        if ($this->isGif()) {
            $max = config('mixpost.max_file_size.gif');
        }

        if ($this->isVideo()) {
            $max = config('mixpost.max_file_size.video');
        }

        return (int)$max;
    }

    private function isImage(): bool
    {
        return Str::before($this->file('file')->getMimeType(), '/') === 'image';
    }

    private function isGif(): bool
    {
        return Str::after($this->file('file')->getMimeType(), '/') === 'gif';
    }

    private function isVideo(): bool
    {
        return Str::before($this->file('file')->getMimeType(), '/') === 'video';
    }

    private function allowedTypes(): array
    {
        return Util::config('mime_types');
    }

    private function getFile(): UploadedFile
    {
        if (!$this->hasFile('file')) {
            try {
                return FileSupport::fromURL($this->get('file'), $this->get('file_name'));
            } catch (Exception $e) {
                abort(400, 'Failed to download file');
            }
        }

        return $this->file('file');
    }

    public function handle(): Media
    {
        $file = $this->getFile();

        UploadingMediaFile::dispatch($file);

        $data = [];

        if ($this->has('adobe_express_doc_id')) {
            $data['adobe_express_doc_id'] = $this->get('adobe_express_doc_id');
        }

        if ($this->has('alt_text')) {
            $data['alt_text'] = $this->get('alt_text');
        }

        return MediaUploader::fromFile($file)
            ->path(self::mediaWorkspacePathWithDateSubpath())
            ->conversions([
                MediaImageResizerConversion::name('thumb')->width(Image::MEDIUM_WIDTH)->height(Image::MEDIUM_HEIGHT),
                MediaVideoThumbConversion::name('thumb')->atSecond(5)
            ])
            ->data($data)
            ->uploadAndInsert();
    }

    public function messages(): array
    {
        if (!$this->file('file')) {
            return [
                'file.required' => __('mixpost::rules.file_required')
            ];
        }

        $fileType = $this->isImage() ? 'image' : 'video';
        $max = $this->max() / 1024;

        return [
            'file.max' => __('mixpost::rules.file_max_size', ['type' => $fileType, 'max' => $max]),
        ];
    }
}
