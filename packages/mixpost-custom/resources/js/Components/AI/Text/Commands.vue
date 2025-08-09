<script setup>
import SecondaryButton from "../../Button/SecondaryButton.vue";
import Flex from "../../Layout/Flex.vue";
import PlusSimple from "../../../Icons/PlusSimple.vue";
import Minus from "../../../Icons/Minus.vue";
import Sparkles from "../../../Icons/Sparkles.vue";

defineEmits(['selected-command']);

defineProps({
    disabled: {
        type: Boolean,
        default: false,
    }
})
</script>
<template>
    <Flex :wrap="true" class="justify-end">
        <SecondaryButton @click="$emit('selected-command', 'rephrase')" :disabled="disabled" size="xs">
            <template #icon><Sparkles/></template>
            {{ $t('ai.rephrase') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'expand')" :disabled="disabled" size="xs">
            <template #icon><PlusSimple/></template>
            {{ $t('ai.expand') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'shorten')" :disabled="disabled" size="xs">
            <template #icon><Minus/></template>
            {{ $t('ai.shorten') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'simplify')" :disabled="disabled" size="xs">
            <template #icon><Sparkles/></template>
            {{ $t('ai.simplify') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'friendly_tone')" :disabled="disabled" size="xs">
            <template #icon><div class="text-lg">😊</div></template>
            {{  $t('ai.more_friendly') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'formal_tone')" :disabled="disabled" size="xs">
            <template #icon><div class="text-lg">🎩</div></template>
            {{ $t('ai.more_formal') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'edgy_tone')" :disabled="disabled" size="xs">
            <template #icon><div class="text-lg">🤘</div></template>
            {{ $t('ai.more_edgy') }}
        </SecondaryButton>

        <SecondaryButton @click="$emit('selected-command', 'engaging_tone')" :disabled="disabled" size="xs">
            <template #icon><div class="text-lg">🤝</div></template>
            {{ $t('ai.more_engaging') }}
        </SecondaryButton>
    </Flex>
</template>
