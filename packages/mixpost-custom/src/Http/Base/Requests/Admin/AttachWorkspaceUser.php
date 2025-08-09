<?php

namespace Inovector\Mixpost\Http\Base\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Inovector\Mixpost\Concerns\UsesUserModel;
use Inovector\Mixpost\Enums\WorkspaceUserRole;
use Inovector\Mixpost\Models\Workspace;

class AttachWorkspaceUser extends FormRequest
{
    use UsesUserModel;

    public function rules(): array
    {
        return [
            'user_id' => ['required', "exists:" . app(self::getUserClass())->getTable() . ",id"],
            'role' => ['required', Rule::in(Arr::map(WorkspaceUserRole::cases(), fn($item) => $item->value))],
            'can_approve' => ['required', 'boolean']
        ];
    }

    public function messages(): array
    {
        return [
            'user_id.exists' => __('mixpost::user.select_user')
        ];
    }

    public function handle()
    {
        $workspace = Workspace::firstOrFailByUuid($this->route('workspace'));

        $workspace->attachUser(
            id: $this->input('user_id'),
            role: WorkspaceUserRole::fromName(Str::upper($this->input('role'))),
            canApprove: $this->input('can_approve', false),
        );
    }
}
