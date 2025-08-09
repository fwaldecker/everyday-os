<?php

namespace Inovector\Mixpost\Http\Base\Requests\Workspace;

use Illuminate\Foundation\Http\FormRequest;
use Inovector\Mixpost\Models\Media;

class UpdateMedia extends FormRequest
{
    public function rules(): array
    {
        return [
            'alt_text' => ['string', 'max:500', 'nullable']
        ];
    }

    public function handle(): int
    {
        $media = Media::where('id', $this->route('id'))->firstOrFail();

        return $media->update([
            'data->alt_text' => $this->input('alt_text')
        ]);
    }
}
