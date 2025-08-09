<script setup>
import Checkbox from "../Form/Checkbox.vue";

defineProps(['modelValue']);

const emits = defineEmits(['update:modelValue']);

const update = (val) => {
    emits('update:modelValue', val)
}
</script>
<template>
    <label>
        <Checkbox v-bind:checked="modelValue" @update:checked="update" :value="false"/>
        <span class="ml-xs">{{ $t('team.can_approve') }}</span>
    </label>
</template>
