<script setup>
import {inject, ref} from "vue";
import {useI18n} from "vue-i18n";
import emitter from "@/Services/emitter";
import {router} from "@inertiajs/vue3";
import useAuth from "@/Composables/useAuth";
import useNotifications from "@/Composables/useNotifications";
import PureButtonLink from "@/Components/Button/PureButtonLink.vue";
import PencilSquare from "../../Icons/PencilSquare.vue";
import Dropdown from "../Dropdown/Dropdown.vue";
import Trash from "../../Icons/Trash.vue";
import DropdownItem from "../Dropdown/DropdownItem.vue";
import DropdownButton from "../Dropdown/DropdownButton.vue";
import QueueList from "../../Icons/QueueList.vue";

const {t: $t} = useI18n()

const routePrefix = inject('routePrefix');
const confirmation = inject('confirmation');
const workspaceCtx = inject('workspaceCtx');

const props = defineProps({
    itemId: {
        type: String,
        required: true,
    }
})

const emit = defineEmits(['onDelete'])

const {notify} = useNotifications();
const {user} = useAuth();

const confirmationDeletion = ref(false);

const resend = () => {
    router.delete(route(`${routePrefix}.webhooks.delete`, {
        workspace: workspaceCtx.id,
        webhook: props.itemId,
    }), {
        onSuccess() {
            confirmationDeletion.value = false;
            emit('onDelete')
            emitter.emit('webhookDeleted', props.itemId);
            dialog.reset();
        },
        onFinish() {
            dialog.isLoading(false)
        }
    })
}
</script>
<template>
    <div>
        <div class="flex flex-row items-center justify-end gap-xs">
            <PureButtonLink :href="route(`${routePrefix}.webhooks.deliveries`, {workspace: workspaceCtx.id, webhook: itemId})"
                            v-tooltip="$t('webhook.deliveries')">
                <QueueList/>
            </PureButtonLink>

            <Dropdown width-classes="w-36" placement="bottom-end">
                <template #trigger>
                    <DropdownButton/>
                </template>

                <template #content>
                    <DropdownItem
                        :href="route(`${routePrefix}.webhooks.edit`, {workspace: workspaceCtx.id, webhook: itemId})">
                        <template #icon>
                            <PencilSquare/>
                        </template>
                        {{ $t('general.edit') }}
                    </DropdownItem>

                    <DropdownItem @click="deleteWebhook" as="button">
                        <template #icon>
                            <Trash class="text-red-500"/>
                        </template>
                        {{ $t('general.delete') }}
                    </DropdownItem>
                </template>
            </Dropdown>
        </div>
    </div>
</template>
