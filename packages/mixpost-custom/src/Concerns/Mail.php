<?php

namespace Inovector\Mixpost\Concerns;

use Illuminate\Notifications\Messages\MailMessage;
use Inovector\Mixpost\Facades\HooksManager;

trait Mail
{
    public function theme(): string
    {
        return 'mixpost::mail.themes.default';
    }

    public function mailMessage(): MailMessage
    {
        $this->beforeSendMailMessage();

        return (new MailMessage)
            ->theme($this->theme());
    }

    public function mailNotificationMessage(): MailMessage
    {
        return $this->mailMessage()
            ->template('mixpost::mail.notification');
    }

    public function beforeSendMailMessage(): void
    {
        HooksManager::doAction('before_send_mail_message', $this);
    }
}
