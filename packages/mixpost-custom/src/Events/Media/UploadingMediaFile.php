<?php

namespace Inovector\Mixpost\Events\Media;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Http\UploadedFile;
use Illuminate\Queue\SerializesModels;
use Inovector\Mixpost\Facades\WorkspaceManager;
use Inovector\Mixpost\Models\Workspace;

class UploadingMediaFile
{
    use Dispatchable, SerializesModels;

    public ?Workspace $workspace;
    public UploadedFile $file;

    public function __construct(UploadedFile $file)
    {
        $this->workspace = WorkspaceManager::current();
        $this->file = $file;
    }
}
