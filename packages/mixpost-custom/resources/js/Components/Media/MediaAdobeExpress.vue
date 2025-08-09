<script setup>
import {onMounted, ref} from 'vue'
import SecondaryButton from "../Button/SecondaryButton.vue";
import AdjustmentsHorizontal from "../../Icons/AdjustmentsHorizontal.vue";
import AdobeExpress from "../../Icons/AdobeExpress.vue";
import Select from "../Form/Select.vue";
import DialogModal from "../Modal/DialogModal.vue";
import PrimaryButton from "../Button/PrimaryButton.vue";
import Input from "../Form/Input.vue";
import VerticalGroup from "../Layout/VerticalGroup.vue";
import useAdobeExpress from "../../Composables/useAdobeExpress.js";
import {toRawIfProxy} from "@/helpers.js";

const emit = defineEmits(['close', 'insert', 'selectMediaInMediaLibrary']);
const showCustomSizeModal = ref(false);

const allowOnlyDigits = (e) => {
  if (!/\d/.test(e.key)) {
    e.preventDefault()
  }
}

const {
  socialMediaSizes,
  customSize,
  loadAdobeSdk,
  openAdobeExpressEditor,
  selected
} = useAdobeExpress(emit);

onMounted(async () => {
  await loadAdobeSdk();
});

defineExpose({selected})
</script>
<template>
  <div class="p-md bg-stone-500 w-auto h-auto rounded-lg ">
    <div class="flex items-center mb-sm">
      <AdobeExpress class="size-9 m-1 mr-xs"/>
      <span>Adobe Express</span>
    </div>
    <div class="flex flex-wrap">
      <SecondaryButton @click="showCustomSizeModal = true" class="m-1 !py-xs">
        <template #icon>
          <AdjustmentsHorizontal/>
        </template>
        <span class="pl-1">{{ $t('media.custom_size') }}</span>
      </SecondaryButton>
      <SecondaryButton v-for="size in socialMediaSizes" @click="openAdobeExpressEditor({ canvasSize: size.value})"
                       class="m-1">
        {{ size.name }}
      </SecondaryButton>
    </div>
  </div>

  <DialogModal :show="showCustomSizeModal"
               max-width="sm"
               :closeable="true"
               @close="showCustomSizeModal = false">
    <template #header>
      {{ $t('media.custom_size') }}
    </template>
    <template #body>
      <VerticalGroup>
        <template #title>
          <label for="cs_width">{{ $t('media.width') }}</label>
        </template>
        <Input type="number"
               v-model="customSize.width"
               id="cs_width"
               @keypress="allowOnlyDigits"
        />
      </VerticalGroup>
      <VerticalGroup class="mt-sm">
        <template #title>
          <label for="cs_height">{{ $t('media.height') }}</label>
        </template>
        <Input type="number"
               v-model="customSize.height"
               id="cs_height"
               @keypress="allowOnlyDigits"
        />
      </VerticalGroup>
      <VerticalGroup class="mt-sm">
        <template #title>
          <label for="cs_unit">{{ $t('media.unit') }}</label>
        </template>
        <Select v-model="customSize.unit" id="unit">
          <option value="px">{{ $t('media.px') }}</option>
          <option value="in">{{ $t('media.inch') }}</option>
          <option value="mm">{{ $t('media.mm') }}</option>
        </Select>
      </VerticalGroup>
    </template>
    <template #footer>
      <SecondaryButton @click="showCustomSizeModal = false" class="mr-xs rtl:mr-0 rtl:ml-xs">
        {{ $t('general.cancel') }}
      </SecondaryButton>
      <PrimaryButton
          @click="() => { showCustomSizeModal = false; openAdobeExpressEditor({ canvasSize: toRawIfProxy(customSize)}); }">
        {{ $t('media.create_design') }}
      </PrimaryButton>
    </template>
  </DialogModal>
</template>
