<script setup>
import {computed, ref, inject} from "vue";
import {clone} from "lodash";
import ExclamationCircleIcon from "@/Icons/ExclamationCircle.vue"
import VideoSolidIcon from "@/Icons/VideoSolid.vue"
import EllipsisVertical from "../../Icons/EllipsisVertical.vue";
import PureButton from "../Button/PureButton.vue";
import DropdownItem from "../Dropdown/DropdownItem.vue";
import Dropdown from "../Dropdown/Dropdown.vue";
import PencilSquare from "../../Icons/PencilSquare.vue";
import TrashIcon from "@/Icons/Trash.vue";
import Photo from "@/Icons/Photo.vue";
import {useForm, usePage} from "@inertiajs/vue3";
import PrimaryButton from "@/Components/Button/PrimaryButton.vue";
import SecondaryButton from "@/Components/Button/SecondaryButton.vue";
import DialogModal from "@/Components/Modal/DialogModal.vue";
import Badge from "@/Components/DataDisplay/Badge.vue";
import Textarea from "../Form/Textarea.vue";
import AddMedia from "@/Components/Media/AddMedia.vue";
import PhotoSolid from "@/Icons/PhotoSolid.vue";
import DangerButton from "@/Components/Button/DangerButton.vue";
import Flex from "@/Components/Layout/Flex.vue";
import AlertText from "@/Components/Util/AlertText.vue";
import useAdobeExpress from "../../Composables/useAdobeExpress.js";
import AdobeExpress from "@/Icons/AdobeExpress.vue";
import Placeholder from "@/Components/Media/Placeholder.vue";

const props = defineProps({
    media: {
        type: Object,
        required: true
    },
    imgHeight: {
        type: String,
        default: 'full'
    },
    placeholderHeight: {
        type: String,
        default: 'default'
    },
    imgWidthFull: {
        type: Boolean,
        default: true
    },
    showCaption: {
        type: Boolean,
        default: true
    },
    editMode: {
        type: Boolean,
        default: true
    },
    showDropdownMenu: {
        type: Boolean,
        default: false
    },
    enableVideoThumb: {
        type: Boolean,
        default: false,
    },
    providersWithVideoThumbEnabled: {
        type: Array,
        default: () => []
    }
})

const workspaceCtx = inject("workspaceCtx");
const routePrefix = inject('routePrefix');

const emits = defineEmits(['update', 'remove', 'open', 'addCustomVideoThumb', 'removeCustomVideoThumb']);

const imgHeightClass = computed(() => {
    return {
        'full': 'h-full',
        'sm': 'h-20'
    }[props.imgHeight]
})

const showDropdownMenu = computed(() => {
    if (!props.editMode && !props.media.is_video) {
        return false;
    }

    if (!props.editMode && props.media.is_video) {
        return props.media.video_custom_thumb_url !== null;
    }

    return props.showDropdownMenu;
});

const showVideoThumb = computed(() => {
    return props.enableVideoThumb && props.media.is_video;
});

const showAltText = computed(() => {
    return !props.media.is_video;
});

const showAltTextForm = ref(false);
const showMediaLibrary = ref(false);
const viewCustomThumbnail = ref(false);

const altTextForm = useForm({
    alt_text: '',
});

const openAltTextForm = (media) => {
    showAltTextForm.value = true;
    altTextForm.id = media.id;
    altTextForm.alt_text = media.alt_text;
};

const closeAltTextForm = () => {
    showAltTextForm.value = null;
    altTextForm.reset();
};

const updateAltText = () => {
    altTextForm.put(
        route(`${routePrefix}.media.update`, {
            id: altTextForm.id,
            workspace: workspaceCtx.id
        }),
        {
            onSuccess: () => {
                const localMedia = clone(props.media);
                localMedia.alt_text = altTextForm.alt_text;
                emits('update', localMedia);
                closeAltTextForm();
            },
        }
    );
};

const removeCustomVideoThumb = () => {
    if (!props.editMode) {
        return;
    }

    emits('removeCustomVideoThumb');
    viewCustomThumbnail.value = false;
}

const {
    openAdobeExpressEditor
} = useAdobeExpress();

</script>
<template>
    <figure :class="{'border border-gray-200 rounded-md p-xs bg-stone-500': showCaption}" class="group relative">
        <slot/>
        <div
            class="relative flex rounded"
            :class="{'border border-red-500 p-md': media.hasOwnProperty('error')}"
        >
            <span v-if="media.is_video && media.thumb_url" class="absolute top-0 left-0 mt-1 ml-1">
                <VideoSolidIcon class="!w-4 !h-4 text-white"/>

                <template v-if="enableVideoThumb && media.video_custom_thumb_url">
                    <PhotoSolid class="!w-4 !h-4 text-white mt-1.5"/>
                </template>
            </span>

            <div v-if="media.hasOwnProperty('error')" class="text-center">
                <ExclamationCircleIcon class="w-8 h-8 mx-auto text-red-500"/>
                <div class="mt-xs">{{ media.name }}</div>
                <div class="mt-xs text-red-500">{{
                        media.error ? media.error : $t('media.error_uploading_media')
                    }}
                </div>
            </div>

            <template v-if="showDropdownMenu && media.alt_text">
                <Badge variant="dark"
                       class="absolute bottom-[3px] left-[3px] text-xs font-medium"
                       v-tooltip="{content: media.alt_text, triggers: ['click'], autoHide: true }"
                >
                    <span class="uppercase">alt</span>
                </Badge>
            </template>

            <template v-if="media.thumb_url">
                <img
                    :src="media.thumb_url"
                    :title="media.name"
                    alt="Image"
                    loading="lazy"
                    class="rounded-md"
                    @click="$emit('open')"
                    :class="[imgHeightClass, {'w-full': imgWidthFull}]"
                />
            </template>

            <template v-if="media.is_video && !media.thumb_url">
                <Placeholder
                    type="video"
                    :widthClass="imgWidthFull ? 'w-full' : 'w-28'"
                    :heightClass="{'default': 'h-28', 'sm': 'h-20'}[placeholderHeight]"
                >
                    <template v-if="enableVideoThumb && media.video_custom_thumb_url">
                        <span class="absolute top-0 left-0 mt-1 ml-1">
                            <PhotoSolid class="!w-4 !h-4 text-black"/>
                        </span>
                    </template>
                </Placeholder>
            </template>

            <div v-if="showDropdownMenu" class="absolute top-0 -mt-xs right-0 -mr-xs">
                <Dropdown widthClasses="w-auto" placement="top-start">
                    <template #trigger>
                        <PureButton class="w-6 h-6 bg-white rounded-full flex items-center justify-center"
                                    @click.prevent>
                            <template #icon>
                                <div class="bg-white border-2 border-gray-400 rounded-full">
                                    <EllipsisVertical class="!w-5 !h-5"/>
                                </div>
                            </template>
                        </PureButton>
                    </template>
                    <template #content>
                        <template v-if="media.adobe_express_doc_id && usePage().props.is_configured_service.adobe_express && editMode">
                            <DropdownItem as="button" @click="() => openAdobeExpressEditor({ documentId: media.adobe_express_doc_id, media: media})">
                                <template #icon>
                                    <AdobeExpress/>
                                </template>
                                {{ $t('media.edit_adobe_express') }}
                            </DropdownItem>
                        </template>
                        <template v-if="showAltText && editMode">
                            <DropdownItem as="button" @click="openAltTextForm(media)">
                                <template #icon>
                                    <PencilSquare/>
                                </template>
                                {{ $t('media.edit_alt_text') }}
                            </DropdownItem>
                        </template>
                        <template v-if="showVideoThumb && editMode">
                            <DropdownItem as="button" @click="showMediaLibrary = true">
                                <template #icon>
                                    <Photo/>
                                </template>
                                {{
                                    media.video_custom_thumb_url ? $t('media.change_video_thumb') : $t('media.add_video_thumb')
                                }}
                            </DropdownItem>
                        </template>
                        <template v-if="showVideoThumb && media.video_custom_thumb_url">
                            <DropdownItem as="button" @click="viewCustomThumbnail = true">
                                <template #icon>
                                    <Photo/>
                                </template>
                                {{ $t('media.view_video_thumb') }}
                            </DropdownItem>
                        </template>
                        <template v-if="editMode">
                            <DropdownItem as="button" @click="emits('remove')">
                                <template #icon>
                                    <TrashIcon class="text-red-500"/>
                                </template>
                                {{ $t('general.remove') }}
                            </DropdownItem>
                        </template>
                    </template>
                </Dropdown>
            </div>
        </div>
        <template v-if="showCaption">
            <figcaption class="mt-xs text-sm break-all">{{ media.name }}</figcaption>
        </template>
    </figure>

    <DialogModal :show="viewCustomThumbnail" @close="viewCustomThumbnail = false">
        <template #header>
            {{ $t('media.view_video_thumb') }}
        </template>
        <template #body>
            <AlertText variant="warning" class="mb-xs">
                {{ $t('media.video_thumb_providers', {'providers': providersWithVideoThumbEnabled.join(', ')}) }}
            </AlertText>
            <figure>
                <img :src="media.video_custom_thumb_url" :alt="$t('media.video_thumb')"/>
            </figure>
        </template>
        <template #footer>
            <Flex>
                <template v-if="editMode">
                    <DangerButton @click="removeCustomVideoThumb" size="md">
                        <template #icon>
                            <TrashIcon/>
                        </template>
                        {{ $t('general.remove') }}
                    </DangerButton>
                </template>
                <SecondaryButton @click="viewCustomThumbnail = false" class="mr-xs">{{
                        $t('general.close')
                    }}
                </SecondaryButton>
            </Flex>
        </template>
    </DialogModal>

    <DialogModal
        :show="showAltTextForm"
        max-width="md"
        :closeable="true"
        :scrollable-body="true"
        @close="closeAltTextForm"
    >
        <template #header>
            {{ $t('media.edit_alt_text') }}
        </template>

        <template #body>
            <div>
                {{
                    $t('media.add_alt_text_for', {'platforms': 'Facebook, Instagram, Threads, X, Mastodon, Pinterest, Bluesky and LinkedIn'})
                }}
            </div>
            <div class="mt-lg">
                <Textarea
                    v-model="altTextForm.alt_text"
                    :placeholder="$t('media.write_alt_text')"
                />
            </div>
        </template>

        <template #footer>
            <SecondaryButton @click="closeAltTextForm" class="mr-xs">{{ $t("general.cancel") }}</SecondaryButton>
            <PrimaryButton
                @click="updateAltText"
                :isLoading="altTextForm.processing"
                :disabled="altTextForm.processing"
            >
                {{ $t("general.save") }}
            </PrimaryButton>
        </template>
    </DialogModal>

    <template v-if="showVideoThumb">
        <AddMedia :disableTrigger="true"
                  :maxSelectedItems="1"
                  :mimeTypes="['image/jpg','image/jpeg','image/png']"
                  :showImmediate="showMediaLibrary"
                  @insert="(el) => $emit('addCustomVideoThumb', el.items[0])"
                  @close="showMediaLibrary = false"/>
    </template>
</template>
