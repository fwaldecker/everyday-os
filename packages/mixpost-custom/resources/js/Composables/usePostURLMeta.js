import {inject} from "vue";

const usePostURLMeta = () => {
    const routePrefix = inject('routePrefix');
    const postCtx = inject('postCtx');

    const setupURLMeta = (oldUrl, newUrl, avoidRepeatableFetchForSameUrl = false) => {
        if (!newUrl) {
            // TODO: should we remove oldUrl from postCtx.urlMeta?
            return;
        }

        if (avoidRepeatableFetchForSameUrl && postCtx.urlMeta.hasOwnProperty(newUrl)) {
            return;
        }

        postCtx.urlMeta[newUrl] = {
            isLoading: true,
            data: null,
            error: null
        };

        axios.get(route(`${routePrefix}.extractUrlMeta`, {url: newUrl}))
            .then((response) => {
                postCtx.urlMeta[newUrl] = {
                    isLoading: false,
                    data: response.data,
                    error: null,
                };
            })
            .catch(() => {
                postCtx.urlMeta[newUrl] = {
                    isLoading: false,
                    data: {
                        default: {
                            title: '',
                            description: '',
                            image: '',
                        },
                        twitter: {
                            title: '',
                            description: '',
                            image: '',
                        },
                    },
                    error: true,
                };
            });
    }

    const setupURLMetaForAllVersions = (versions) => {
        versions.forEach((version) => {
            version.content.forEach((content) => {
                if (content.hasOwnProperty('url') && content['url']) {
                    setupURLMeta('', content['url'], true);
                }
            });
        });
    }

    const getURLMeta = (url) => {
        return postCtx.urlMeta.hasOwnProperty(url) ? postCtx.urlMeta[url] : null;
    }

    return {
        setupURLMeta,
        setupURLMetaForAllVersions,
        getURLMeta
    }
}

export default usePostURLMeta;
