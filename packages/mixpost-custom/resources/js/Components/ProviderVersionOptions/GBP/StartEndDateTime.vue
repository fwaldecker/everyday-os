<script setup>
import HorizontalGroup from "@/Components/Layout/HorizontalGroup.vue";
import Label from "@/Components/Form/Label.vue";
import Flex from "@/Components/Layout/Flex.vue";
import Switch from "@/Components/Form/Switch.vue";
import DatePicker from "@/Components/Form/DatePicker.vue";
import TimePicker from "@/Components/Form/TimePicker.vue";

defineProps({
    options: {
        type: Object,
        required: true
    },
    showTimeFields: {
        type: Boolean,
        default: false
    }
})
</script>
<template>
    <HorizontalGroup class="w-full">
        <template #title>
            <Label for="start_date">{{ $t('service.gbp.start_date') }}</label>
        </template>

        <DatePicker v-model="options.start_date" id="start_date" class="w-32"/>
    </HorizontalGroup>

    <HorizontalGroup v-if="showTimeFields && options.event_has_time" class="mt-xs">
        <template #title>
            <Label>{{ $t('service.gbp.start_time') }}</label>
        </template>

        <TimePicker v-model="options.start_time" class="w-32"/>
    </HorizontalGroup>

    <HorizontalGroup class="w-full mt-xs">
        <template #title>
            <Label for="end_date">{{ $t('service.gbp.end_date') }}</label>
        </template>

        <DatePicker v-model="options.end_date" id="end_date" class="w-32"/>
    </HorizontalGroup>

    <HorizontalGroup v-if="showTimeFields && options.event_has_time" class="mt-xs">
        <template #title>
            <Label>{{ $t('service.gbp.end_time') }}</label>
        </template>

        <TimePicker v-model="options.end_time" class="w-32"/>
    </HorizontalGroup>

    <HorizontalGroup v-if="showTimeFields" class="mt-md md:mt-xs">
        <Flex :responsive="false">
            <Switch id="event_has_time"
                    v-model="options.event_has_time"
            />
            <Label for="event_has_time" class="mb-0!">{{ $t('service.gbp.add_time') }}</Label>
        </Flex>
    </HorizontalGroup>
</template>
