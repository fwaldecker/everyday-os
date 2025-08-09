<script setup>
import {ref, onMounted, watch} from "vue";
import {useI18n} from "vue-i18n";
import {format, addHours, parseISO} from "date-fns"
import {utcToZonedTime} from "date-fns-tz";
import useSettings from "@/Composables/useSettings";
import {isTimePast, convertTime12to24} from "@/helpers";
import DialogModal from "@/Components/Modal/DialogModal.vue"
import PrimaryButton from "@/Components/Button/PrimaryButton.vue"
import SecondaryButton from "@/Components/Button/SecondaryButton.vue"
import ExclamationCircleIcon from "@/Icons/ExclamationCircle.vue"
import {Link} from '@inertiajs/vue3'
import FlatPickr from 'vue-flatpickr-component';
import 'flatpickr/dist/flatpickr.css';
import '@css/overrideFlatPickr.css'
import useDateTimePicker from "@/Composables/useDateTimePicker.js";

const props = defineProps({
    show: {
        type: Boolean,
        default: false,
    },
    date: {
        type: String,
        default: '',
    },
    time: {
        type: String,
        default: '',
    },
    isSubmitActive: {
        type: Boolean,
        default: true
    }
})

const emit = defineEmits(['close', 'update']);

const { t: $t } = useI18n()

const date = ref();
const time = ref();
const hasErrors = ref(false);

const timePicker = ref();

const {timeZone, timeFormat} = useSettings();
const {getLocaleConfig, getPrevArrow, getNextArrow} = useDateTimePicker();

const setDateTime = () => {
    if (props.show) {
        if (!props.date && !props.time) {
            // Display the next time if the date and time are null
            const currentTime = utcToZonedTime(new Date().toISOString(), timeZone)

            const [nextDate, nextHour] = format(addHours(currentTime, 1), 'yyyy-MM-dd H').split(' ');

            date.value = nextDate
            time.value = `${nextHour}:00`

            return;
        }

        date.value = props.date;
        time.value = props.time;
    }
}

const validate = () => {
    return new Promise(resolve => {
        // Prevent time value in the past
        const selected = new Date(parseISO(`${date.value} ${time.value}`));

        if (isTimePast(selected, timeZone)) {
            hasErrors.value = true;

            resolve(false);
            return;
        }

        hasErrors.value = false;

        resolve(true);
    });
}

onMounted(() => {
    setDateTime();
});

watch(() => props.show, () => {
    if (props.show) {
        setDateTime();
    }
});

watch([date, time], () => {
    validate();
});

const confirm = async () => {
    const hour = timePicker.value.querySelector('.flatpickr-hour').value;
    const minutes = timePicker.value.querySelector('.flatpickr-minute').value;

    if (timeFormat === 24) {
        time.value = `${hour}:${minutes}`; // we make sure we have the data that was entered manually (on keyup)
    }

    if (timeFormat === 12) {
        const ampm = timePicker.value.querySelector('.flatpickr-am-pm').innerText;

        time.value = convertTime12to24(`${hour}:${minutes} ${ampm}`); // we make sur sure we have the data that was entered manually (on keyup)
    }

    const isValid = await validate();

    if (!isValid) {
        return;
    }

    emit('update', {
        date: date.value,
        time: time.value
    })

    close();
}

const close = () => {
    date.value = '';
    time.value = '';
    emit('close');
};

const configDatePicker = {
    inline: true,
    dateFormat: 'Y-m-d',
    minDate: "today",
    allowInput: false,
    monthSelectorType: 'static',
    yearSelectorType: 'static',
    static: true,
    locale: getLocaleConfig(),
    prevArrow: getPrevArrow(),
    nextArrow: getNextArrow()
}

const configTimePicker = {
    inline: true,
    timeFormat: 'H:i',
    noCalendar: true,
    enableTime: true,
    time_24hr: timeFormat === 24
}
</script>
<template>
    <DialogModal :show="show"
                 max-width="sm"
                 :closeable="true"
                 @close="close">
        <template #body>
            <div v-if="show" class="pickTime flex flex-col">
                <FlatPickr v-model="date" :config="configDatePicker"/>

                <div class="flex items-center justify-center mx-auto mt-lg">
                    <div class="mr-xs text-gray-400">{{ $t('general.time') }}</div>
                    <div class="w-auto" ref="timePicker">
                        <FlatPickr v-model="time" :config="configTimePicker"/>
                    </div>
                </div>
                <div class="text-sm flex items-center justify-center mt-sm">
                    <div class="mr-1">{{ timeZone }}</div>
                    <Link :href="route('mixpost.profile.index')" v-tooltip="$t('post.post_scheduled_timezone')">
                        <ExclamationCircleIcon class="w-4! h-4!"/>
                    </Link>
                </div>
                <div v-if="hasErrors" class="mt-xs text-center text-red-500">{{ $t('post.past_selected_date') }}
                </div>
            </div>
        </template>

        <template #footer>
            <SecondaryButton @click="close" class="mr-xs">{{ $t('general.cancel') }}</SecondaryButton>
            <PrimaryButton @click="confirm" :disabled="hasErrors || !isSubmitActive">{{ $t('post.pick_time') }}
            </PrimaryButton>
        </template>
    </DialogModal>
</template>
