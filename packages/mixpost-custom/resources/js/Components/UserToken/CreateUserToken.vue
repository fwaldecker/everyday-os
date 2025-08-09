<script setup>
import {inject, ref} from "vue";
import {useAPIForm} from "../../Composables/useAPIForm";
import useHttpClient from "../../Composables/useHttpClient";
import DialogModal from "../Modal/DialogModal.vue";
import SecondaryButton from "../Button/SecondaryButton.vue";
import Input from "../Form/Input.vue";
import Label from "../Form/Label.vue";
import Error from "../Form/Error.vue";
import VerticalGroup from "../Layout/VerticalGroup.vue";
import LabelSuffix from "../Form/LabelSuffix.vue";
import PrimaryButton from "../Button/PrimaryButton.vue";
import Alert from "../Util/Alert.vue";
import Select from "../Form/Select.vue";
import Flex from "../Layout/Flex.vue";
import ClipboardCard from "../Util/ClipboardCard.vue";
import SuccessButton from "../Button/SuccessButton.vue";

const routePrefix = inject('routePrefix');

const emit = defineEmits(['added']);

const show = ref(false);
const createdToken = ref('');

const form = useAPIForm({
    name: '',
    expiration: 'days-7',
    expires_at: '',
});

const open = () => {
    show.value = true;
}

const close = () => {
    show.value = false;
    form.reset();
    form.clearErrors();
}

const {onCatch} = useHttpClient();

const store = () => {
    form.post(route(`${routePrefix}.profile.accessTokens.store`), {
        onSuccess(response) {
            close();
            form.reset();
            createdToken.value = response.plain_text_token;
            emit('added');
        },
        onError(error) {
            onCatch(error, store);
        }
    });
}
</script>
<template>
    <PrimaryButton @click="open">{{ $t('access_token.create') }}</PrimaryButton>

    <DialogModal :show="show"
                 max-width="md"
                 :closeable="true"
                 :scrollable-body="true"
                 @close="close">
        <template #header>
            {{ $t('access_token.create') }}
        </template>

        <template #body>
            <VerticalGroup>
                <template #title>
                    <label for="token_name">{{ $t('general.name') }}
                        <LabelSuffix :danger="true">*</LabelSuffix>
                    </label>
                </template>

                <Input type="text"
                       v-model="form.name"
                       :error="form.errors.name !== undefined"
                       id="token_name"
                       :placeholder="$t('access_token.name_placeholder')"/>

                <template #footer>
                    <Error :message="form.errors.name"/>
                </template>
            </VerticalGroup>

            <VerticalGroup class="mt-lg">
                <template #title>
                    <label for="expiration">{{ $t('access_token.expiration') }}
                        <LabelSuffix :danger="true">*</LabelSuffix>
                    </label>
                </template>

                <Flex class="w-full">
                    <Select v-model="form.expiration" :error="form.errors.expiration !== undefined" id="expiration">
                        <option value="days-7">{{ $t('calendar.days', {count: 7}) }}</option>
                        <option value="days-30">{{ $t('calendar.days', {count: 30}) }}</option>
                        <option value="days-60">{{ $t('calendar.days', {count: 60}) }}</option>
                        <option value="days-90">{{ $t('calendar.days', {count: 90}) }}</option>
                        <option value="never-expires">{{ $t('access_token.never_expires') }}</option>
                        <option value="custom">{{ $t('general.custom') }}</option>
                    </Select>

                    <template v-if="form.expiration === 'custom'">
                        <Input type="date"
                               v-model="form.expires_at"
                               :error="form.errors.expires_at"
                               id="expiration"/>
                    </template>
                </Flex>

                <template #footer>
                    <Error :message="form.errors.expiration"/>
                    <Error :message="form.errors.expires_at"/>
                </template>
            </VerticalGroup>
        </template>

        <template #footer>
            <SecondaryButton @click="close" class="mr-xs">{{ $t('general.cancel') }}</SecondaryButton>
            <PrimaryButton @click="store"
                           :disabled="form.processing"
                           :isLoading="form.processing">
                {{ $t('general.create') }}
            </PrimaryButton>
        </template>
    </DialogModal>

    <DialogModal :show="createdToken !== ''"
                 max-width="xl"
                 :closeable="true"
                 :scrollable-body="true"
                 @close="createdToken = ''">
        <template #header>
            {{ $t('access_token.create') }}
        </template>
        <template #body>
            <template v-if="createdToken">
                <Alert variant="warning" :closeable="false">
                    {{ $t('access_token.copy_token') }}
                </Alert>

                <ClipboardCard class="mt-lg">{{ createdToken }}</ClipboardCard>
            </template>
        </template>
        <template #footer>
            <SuccessButton @click="createdToken = ''">
                {{ $t('system.stored_safely') }}
            </SuccessButton>
        </template>
    </DialogModal>
</template>
