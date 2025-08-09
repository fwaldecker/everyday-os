import {inject, reactive} from "vue";
import {usePage} from "@inertiajs/vue3";
import NProgress from "nprogress";
import usePreloader from "@/Composables/usePreloader.js";
import useMedia from "@/Composables/useMedia.js";
import {base64ToFile, applyLowZIndex, removeLowZIndex} from "@/helpers.js";
import useNotifications from "./useNotifications.js";
import {useI18n} from "vue-i18n";

const {notify} = useNotifications();

const useAdobeExpress = (emit) => {
    const {t: $t} = useI18n();
    const {startPreloader, stopPreloader} = usePreloader({useGlobal: true});

    const workspaceCtx = inject('workspaceCtx');

    const customSize = reactive({
        width: 1080,
        height: 1080,
        unit: 'px'
    });

    const socialMediaSizes = [
        {
            name: $t('media.fb_post'),
            value: 'Facebook'
        },
        {
            name: $t('media.fb_story'),
            value: 'FacebookStory'
        },
        {
            name: $t('media.ig_portrait_post'),
            value: 'InstagramPortraitPost'
        }, {
            name: $t('media.ig_square_post'),
            value: 'Instagram'
        }, {
            name: $t('media.ig_story'),
            value: 'InstagramStory'
        }, {
            name: $t('media.linkedin_post'),
            value: 'LinkedinPost'
        }, {
            name: $t('media.x_post'),
            value: 'Twitter'
        }, {
            name: $t('media.pinterest_post'),
            value: 'Pinterest'
        },
    ];

    const {
        selected,
        toggleSelect
    } = useMedia('mixpost.media.fetchUploads', {workspace: workspaceCtx.id}, 1);

    const loadAdobeSdk = () => {
        if (window.CCEverywhere) return;
        if (window.ccEverywhereInstance) return;

        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = 'https://cc-embed.adobe.com/sdk/v4/CCEverywhere.js';
            script.async = true;
            script.onload = async () => {
                window.ccEverywhereInstance = await window.CCEverywhere.initialize({
                    clientId: usePage().props.service_configs.adobe_express.client_id,
                    appName: usePage().props.app.name
                });
            };
            script.onerror = reject;
            document.body.appendChild(script);
        });
    };

    const uploadFile = (asset) => {
        const formData = new FormData();

        if (asset.dataType === 'base64') {
            formData.append("file", base64ToFile(asset.data, `adobe-express-image`));
        } else {
            formData.append("file", asset.data);
            formData.append("file_name", 'adobe-express-video.mp4');
        }
        formData.append('adobe_express_doc_id', asset.documentId);

        NProgress.start();
        startPreloader();

        return new Promise((resolve, reject) => {
            axios.post(route('mixpost.media.upload', {workspace: workspaceCtx.id}), formData)
                .then(function (response) {
                    NProgress.done();
                    stopPreloader();
                    resolve(response.data);
                })
                .catch(function (error) {
                    NProgress.done();
                    NProgress.remove();
                    stopPreloader();
                    reject(error);
                });
        });
    };

    /*
    * 'create' requires only 'canvasSize' param
    * 'edit' requires 'documentId' && 'media' params
    */
    const openAdobeExpressEditor = ({canvasSize = null, documentId = null, media = null}) => {
        if (!window.ccEverywhereInstance) {
            console.error('Adobe Express SDK not initialized.');
            return;
        }

        const isCreateMode = canvasSize !== null && !documentId && !media;
        const isEditMode = !isCreateMode;

        const docConfig = {};
        const appConfig = {
            callbacks: {
                onLoadInit: applyUIChanges,
                onCancel: resetUIChanges,
                onPublish: async (intent, publishParams) => {
                    resetUIChanges();

                    const asset = publishParams.asset[0];
                    asset.documentId = publishParams.documentId;

                    await uploadFile(asset)
                        .then((uploadedMedia) => {
                            notify('success', $t('media.saved'));

                            if (isCreateMode) {
                                toggleSelect(uploadedMedia);
                                emit('insert');
                                emit('selectMediaInMediaLibrary', uploadedMedia);
                                emit('close');
                            }

                            if (isEditMode) {
                                for (const key in uploadedMedia) {
                                    if (media.hasOwnProperty(key)) {
                                        media[key] = uploadedMedia[key];
                                    }
                                }
                            }
                        });
                }
            },
            allowedFileTypes: ['image/png', 'image/jpeg', 'video/mp4'],
        };

        if (isCreateMode) {
            docConfig.canvasSize = typeof canvasSize === 'object' ? {
                width: parseInt(canvasSize.width),
                height: parseInt(canvasSize.height),
                unit: canvasSize.unit
            } : canvasSize

            window.ccEverywhereInstance.editor.create(docConfig, appConfig);
        }

        if (isEditMode) {
            docConfig.documentId = documentId;
            appConfig.selectedCategory = "media";
            window.ccEverywhereInstance.editor.edit(docConfig, appConfig);
        }
    };

    const applyUIChanges = () => {
        applyLowZIndex({classes: ['default-sidebar', 'modal-visible']});
    };

    const resetUIChanges = () => {
        removeLowZIndex({classes: ['default-sidebar', 'modal-visible']});
    };

    return {
        socialMediaSizes,
        customSize,
        loadAdobeSdk,
        openAdobeExpressEditor,
        selected
    }
}

export default useAdobeExpress;
