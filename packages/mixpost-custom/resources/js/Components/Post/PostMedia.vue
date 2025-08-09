<script setup>
import {ref} from "vue";
import {clone, startsWith} from "lodash";
import Draggable from 'vuedraggable'
import usePost from "@/Composables/usePost";
import DialogModal from "@/Components/Modal/DialogModal.vue"
import MediaFile from "@/Components/Media/MediaFile.vue";
import SecondaryButton from "@/Components/Button/SecondaryButton.vue";
import DangerButton from "@/Components/Button/DangerButton.vue";

const props = defineProps({
    media: {
        type: Array,
        required: true
    },
    showItemDropdownMenu: {
        type: Boolean,
        default: true
    },
    videoThumbs: {
        type: Array,
        required: true
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

const emits = defineEmits(['updated', 'videoThumbsUpdated']);

const {editAllowed} = usePost();

const showView = ref(false);
const openedItem = ref({});

const isVideo = (mime_type) => {
    return startsWith(mime_type, 'video')
}

const open = (item) => {
    openedItem.value = item;
    showView.value = true;
}

const close = () => {
    showView.value = false;
    openedItem.value = {};
}

const remove = (id) => {
    const index = props.media.findIndex(item => item.id === id);

    const items = clone(props.media);
    items.splice(index, 1);

    //remove thumbnail only if there are no other media with the provided id
    if(props.media.findIndex(item => item.id === id)){
        const thumbs = clone(props.videoThumbs).filter(thumb => {
            return thumb.media_id !== id;
        });
        emits('videoThumbsUpdated', thumbs);
    }

    emits('updated', items);
    close();
}

const update = (media) => {
    const items = clone(props.media);
    items.forEach(item => {
        if(item.id === media.id){
            item.alt_text = media.alt_text
        }
    });
    emits('updated', items);
}
const syncVideoThumb = (media, mode, thumbnail = {}) => {
    if(!['add_thumbnail', 'remove_thumbnail'].includes(mode)){
        return;
    }

    const items = clone(props.media);
    let thumbs = clone(props.videoThumbs);

    items.forEach(item => {
        if(item.id === media.id){
            thumbs = thumbs.filter(thumb => {
                return thumb.media_id !== media.id;
            });
            if(mode === 'add_thumbnail'){
                item.video_custom_thumb_url = thumbnail.url;
                thumbs.push({
                    media_id: media.id,
                    thumb_id: thumbnail.id
                });
            } else if(mode === 'remove_thumbnail'){
                item.video_custom_thumb_url = null;
            }
        }
    } );

    emits('updated', items);
    emits('videoThumbsUpdated', thumbs);
}
</script>
<template>
    <div :class="{'mt-xs': media.length}">
        <Draggable
            :list="media"
            :disabled="!editAllowed"
            v-bind="{
                animation: 200,
                group: 'media'
            }"
            item-key="id"
            class="flex flex-wrap gap-sm"
        >
            <template #item="{element}">
                <div role="button" class="cursor-pointer">
                    <MediaFile :media="element"
                               imgHeight="sm"
                               placeholderHeight="sm"
                               :imgWidthFull="false"
                               :showCaption="false"
                               :editMode="editAllowed"
                               :showDropdownMenu="showItemDropdownMenu"
                               :enableVideoThumb="enableVideoThumb"
                               :providersWithVideoThumbEnabled="providersWithVideoThumbEnabled"
                               @open="open(element)"
                               @update="(el) => update(el)"
                               @remove="remove(element.id)"
                               @addCustomVideoThumb="(el) => syncVideoThumb(element, 'add_thumbnail', el)"
                               @removeCustomVideoThumb="() => syncVideoThumb(element, 'remove_thumbnail')"
                    />
                </div>
            </template>
        </Draggable>
    </div>

    <DialogModal :show="showView" @close="close">
        <template #header>
            {{ $t('post.view_media') }}
        </template>

        <template #body>
            <figure>
                <figcaption class="mb-xs text-sm">{{ openedItem.name }}</figcaption>

                <video v-if="isVideo(openedItem.mime_type)" class="w-auto h-full" controls>
                    <source :src="openedItem.url" :type="openedItem.mime_type">
                    {{ $t('error.browser_video_unsupported') }}
                </video>

                <img v-else :src="openedItem.url" alt="Image"/>
            </figure>
        </template>

        <template #footer>
            <SecondaryButton @click="close" class="mr-xs">{{ $t('general.close') }}</SecondaryButton>
            <DangerButton v-if="editAllowed" @click="remove(openedItem.id)">{{ $t('general.remove') }}</DangerButton>
        </template>
    </DialogModal>
</template>
