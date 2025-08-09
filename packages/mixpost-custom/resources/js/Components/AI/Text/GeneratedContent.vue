<script setup>
import {ref} from "vue";
import Flex from "../../Layout/Flex.vue";
import PrimaryButton from "../../Button/PrimaryButton.vue";
import Refresh from "../../../Icons/Refresh.vue";
import SecondaryButton from "../../Button/SecondaryButton.vue";
import ClipboardButton from "../../Util/ClipboardButton.vue";

const props = defineProps({
    text: {
        type: String,
        required: true,
    },
    buttonsDisabled: {
        type: Boolean,
        default: false,
    },
    insertButtonName: {
        type: String,
        default: '',
    }
})

defineEmits(['clickInsert', 'clickRetry']);

const dom = ref('')
</script>
<template>
    <div class="p-md rounded-md border border-primary-500">
        <p ref="dom">{{ text }}</p>

        <Flex class="mt-md justify-between items-center">
            <ClipboardButton :htmlElm="dom"
                             :show-text="false"
                             size="xs"
                             :disabled="buttonsDisabled"
                             component="PureButton"
                             v-tooltip="$t('system.copy')"
            />

            <Flex>
                <SecondaryButton @click="$emit('clickRetry')" size="xs"
                                 :disabled="buttonsDisabled">
                    <template #icon>
                        <Refresh/>
                    </template>
                    {{ $t('general.retry') }}
                </SecondaryButton>

                <PrimaryButton
                    @click="$emit('clickInsert')"
                    size="sm"
                    :disabled="buttonsDisabled">
                    {{ insertButtonName ? insertButtonName : $t('general.insert')}}
                </PrimaryButton>
            </Flex>
        </Flex>
    </div>
</template>
