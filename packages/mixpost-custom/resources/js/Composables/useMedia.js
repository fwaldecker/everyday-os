import NProgress from 'nprogress'
import {computed, nextTick, ref, watch} from "vue";
import {useI18n} from "vue-i18n";
import {debounce} from "lodash";
import useNotifications from "@/Composables/useNotifications";
import {usePage} from "@inertiajs/vue3";

const useMedia = (routeName = 'mixpost.media.fetchUploads',
                  routeParams = {},
                  maxSelectedItems = -1,
                  mimeTypes = [],
                  selectedItems = []) => {
    const {t: $t} = useI18n();
    const {notify} = useNotifications();

    const activeTab = ref('uploads');

    const tabs = computed(() => {
        const sources = ['uploads', 'stock'];
        if(!mimeTypes.length || mimeTypes.length && mimeTypes.includes('image/gif')){
            sources.push('gifs');
        }
        if(usePage().props.is_configured_service.adobe_express){
            sources.push('new_design');
        }
        return sources;
    })

    const isLoaded = ref(false);
    const isDownloading = ref(false);
    const isDeleting = ref(false);
    const page = ref(1);
    const items = ref([]);
    const endlessPagination = ref(null);
    const keyword = ref('');

    const selected = ref(selectedItems);
    const toggleSelect = (media) => {
        const index = selected.value.findIndex(item => item.id === media.id);

        if (index < 0 && !media.hasOwnProperty('error')) {
            if(maxSelectedItems === 1) {
                selected.value = [media];
            } else if(selected.value.length < maxSelectedItems || maxSelectedItems === -1){ // -1 means infinite
                selected.value.push(media);
            }
        }

        if (index >= 0) {
            selected.value.splice(index, 1);
        }
    }

    const deselectAll = () => {
        selected.value = [];
    }

    const isSelected = (media) => {
        const index = selected.value.findIndex(item => item.id === media.id);

        return index !== -1;
    }

    const fetchItems = (appendResult = true) => {
        if (!page.value) {
            return;
        }

        NProgress.start();

        const params = {
            page: page.value,
            keyword: keyword.value,
            mime_types: mimeTypes
        };

        axios.get(route(routeName, routeParams), { params })
            .then(function (response) {
                const nextLink = response.data.links.next;

                if (nextLink) {
                    page.value = response.data.links.next.split('?page=')[1];
                }

                if (!nextLink) {
                    page.value = 0;
                }

                if (!appendResult) {
                    items.value = response.data.data;
                }

                if (appendResult) {
                    items.value = [...items.value, ...response.data.data];
                }
            }).catch(() => {
                notify('error', $t('media.error_retrieving_media'));
            }).finally(() => {
                NProgress.done();
                isLoaded.value = true;
            });
    }

    const downloadExternal = (items, callback) => {
        isDownloading.value = true;
        NProgress.start();

        axios.post(route('mixpost.media.download', routeParams), {
            items,
            from: activeTab.value,
        }).then((response) => {
            callback(response);
        }).catch(() => {
            notify('error', $t('media.error_downloading_media'));
        }).finally(() => {
            isDownloading.value = false;
            NProgress.done();
            NProgress.remove();
        })
    }

    const removeItems = (ids) => {
        items.value = items.value.filter((item) => !ids.includes(item.id));
    }

    const getMediaCrediting = (mediaCollection) => {
        let text = '';

        mediaCollection.forEach((item) => {
            if (item.source === 'Unsplash') {
                text += `\nPhoto by ${item.author} on Unsplash`;
            }
            if (item.source === 'Pexels') {
                text += `\nPhoto by ${item.author} on Pexels`;
            }
        });

        return text;
    }

    const deletePermanently = (items, callback) => {
        isDeleting.value = true;
        NProgress.start();

        axios.delete(route('mixpost.media.delete', routeParams), {
            data: {
                items
            }
        }).then(() => {
            callback();
        }).catch(() => {
            notify('error', $t('media.error_deleting_media'));
        }).finally(() => {
            isDeleting.value = false;
            NProgress.done();
            NProgress.remove();
        })
    }

    const createObserver = () => {
        const observer = new IntersectionObserver((entries) => {
            const isIntersecting = entries[0].isIntersecting;

            if (isIntersecting) {
                fetchItems();
            }
        });

        nextTick(() => {
            observer.observe(endlessPagination.value);
        });
    }

    watch(keyword, debounce(() => {
        page.value = 1;
        fetchItems(false);
    }, 300));

    return {
        activeTab,
        tabs,
        isLoaded,
        isDownloading,
        isDeleting,
        keyword,
        page,
        items,
        endlessPagination,
        selected,
        getMediaCrediting,
        downloadExternal,
        deletePermanently,
        removeItems,
        createObserver,
        toggleSelect,
        deselectAll,
        isSelected
    }
}

export default useMedia;
