<script setup>
import {computed, inject, ref} from "vue";
import useHttpClient from "../../../Composables/useHttpClient";
import {useAPIForm} from "../../../Composables/useAPIForm";
import Label from "../../Form/Label.vue";
import Select from "../../Form/Select.vue";
import Textarea from "../../Form/Textarea.vue";
import VerticalGroup from "../../Layout/VerticalGroup.vue";
import Flex from "../../Layout/Flex.vue";
import PrimaryButton from "../../Button/PrimaryButton.vue";
import SecondaryButton from "../../Button/SecondaryButton.vue";
import Preloader from "./Preloader.vue";
import GeneratedContent from "./GeneratedContent.vue";
import DraftContent from "./DraftContent.vue";
import Commands from "./Commands.vue";
import Sparkles from "../../../Icons/Sparkles.vue";

const routePrefix = inject('routePrefix');
const workspaceCtx = inject('workspaceCtx');

defineEmits(['insert']);

const props = defineProps({
    characterLimit: {
        type: Number,
        default: 1000,
    }
})

const form = useAPIForm({
    prompt: '',
    tone: 'neutral',
    character_limit: (props.characterLimit === 0 || props.characterLimit > 1000) ? 1000 : props.characterLimit,
    text: '', // Will use on modify
    command: '', // Will use on modify
});

const state = ref('form');
const textGenerated = ref(false);
const textGeneratedDisabled = ref(false);
const generatedText = ref('');

const showForm = computed(() => state.value === 'form');

const changeState = (newState) => {
    state.value = newState;
}

const displayForm = () => {
    changeState('form');
    textGeneratedDisabled.value = true;
}

const displayResult = () => {
    changeState('result');
    textGeneratedDisabled.value = false;
}

const resetAll = () => {
    form.reset();
    displayForm();
    textGenerated.value = false;
    textGeneratedDisabled.value = false;
    generatedText.value = '';
}

const {onCatch} = useHttpClient();

const generate = () => {
    displayResult();

    form.transform((data) => ({
        prompt: data.prompt,
        tone: data.tone,
        character_limit: data.character_limit,
    })).post(route(`${routePrefix}.ai.text.generate`, {workspace: workspaceCtx.id}), {
        onSuccess(response) {
            generatedText.value = response.text;
            textGenerated.value = true;
        },
        onError(error) {
            onCatch(error);
        }
    });
}

const modify = () => {
    displayResult();

    form.transform((data) => ({
        text: data.text,
        command: data.command,
        character_limit: data.character_limit > 1000 ? 1000 : data.character_limit,
    })).post(route(`${routePrefix}.ai.text.modify`, {workspace: workspaceCtx.id}), {
        onSuccess(response) {
            generatedText.value = response.text;
        },
        onError(error) {
            onCatch(error);
        }
    });
}

const retry = () => {
    if (!form.command) {
        generate();
        return;
    }

    modify();
}
</script>
<template>
    <template v-if="showForm">
        <VerticalGroup>
            <template #title>
                <label for="prompt">{{ $t('ai.tell_ai') }}</label>
            </template>

            <Textarea v-model="form.prompt"
                      id="prompt"
                      rows="4"
                      autofocus
                      :placeholder="$t('ai.write_about')"
            />
        </VerticalGroup>

        <VerticalGroup class="mt-lg">
            <template #title>
                <label for="tone">{{ $t('ai.tone_') }}</label>
            </template>

            <Select v-model="form.tone" id="tone">
                <option value="neutral">{{ $t('ai.tone.neutral') }}</option>
                <option value="friendly">😊 {{ $t('ai.tone.friendly') }}</option>
                <option value="formal">🎩 {{ $t('ai.tone.formal') }}</option>
                <option value="edgy">🤘 {{ $t('ai.tone.edgy') }}</option>
                <option value="engaging">🤝 {{ $t('ai.tone.engaging') }}</option>
            </Select>
        </VerticalGroup>

        <Flex class="mt-lg justify-end">
            <template v-if="textGenerated">
                <SecondaryButton @click="displayResult">{{ $t('general.cancel') }}</SecondaryButton>
            </template>

            <PrimaryButton @click="generate"
                           size="md"
                           :isLoading="form.processing"
                           :disabled="form.processing || !form.prompt">
                <template #icon>
                    <Sparkles/>
                </template>
                <span v-if="!textGeneratedDisabled">{{ $t('general.generate') }}</span>
                <span v-else>{{ $t('general.generate_new') }}</span>
            </PrimaryButton>
        </Flex>
    </template>

    <template v-if="!showForm">
        <DraftContent @click="displayForm"
                      @clickClear="resetAll"
                      :clearable="!form.processing"
                      class="mt-xs">
            {{ form.prompt }}
        </DraftContent>
    </template>

    <template v-if="form.processing">
        <Preloader/>
    </template>

    <template v-if="textGenerated && !form.processing">
        <GeneratedContent @clickInsert="$emit('insert', generatedText)"
                          @clickRetry="retry"
                          :text="generatedText"
                          :buttonsDisabled="textGeneratedDisabled"
                          insertButtonName="Insert"
                          class="mt-lg"
                          :class="{'opacity-50': textGeneratedDisabled}"
        />

        <Commands @selected-command="($event)=> {
                form.command = $event;
                form.text = generatedText;
                modify();
            }" :disabled="textGeneratedDisabled" class="mt-lg"/>
    </template>
</template>
