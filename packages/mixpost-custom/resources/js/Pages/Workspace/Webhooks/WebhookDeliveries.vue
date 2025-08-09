<script setup>
import {inject, onMounted, ref, watch} from "vue";
import {Head, router} from '@inertiajs/vue3';
import useNotifications from "@/Composables/useNotifications";
import useRouter from "../../../Composables/useRouter";
import {cloneDeep, pickBy, throttle} from "lodash";
import PageHeader from "@/Components/DataDisplay/PageHeader.vue";
import WebhookAction from "../../../Components/Webhook/WebhookAction.vue";
import Panel from "../../../Components/Surface/Panel.vue";
import Flex from "../../../Components/Layout/Flex.vue";
import Pagination from "../../../Components/Navigation/Pagination.vue";
import NoResult from "../../../Components/Util/NoResult.vue";
import WebhookDeliveryItem from "../../../Components/Webhook/WebhookDeliveryItem.vue";
import WebhookDeliveryItemView from "../../../Components/Webhook/WebhookDeliveryItemView.vue";
import Tabs from "../../../Components/Navigation/Tabs.vue";
import Tab from "../../../Components/Navigation/Tab.vue";

const props = defineProps({
    filter: {
        type: Object,
        default: {}
    },
    webhook: {
        type: Object,
        required: true
    },
    deliveries: {
        type: Object,
    }
})

const routePrefix = inject('routePrefix');
const workspaceCtx = inject('workspaceCtx')
const confirmation = inject('confirmation');
const authPasswordConfirmation = inject('authPasswordConfirmation');

const {notify} = useNotifications();
const {onError} = useRouter();

const filter = ref({
    status: props.filter.status
})

const selectedDelivery = ref(null);

onMounted(() => {
    if (props.deliveries.data.length) {
        selectDelivery(props.deliveries.data[0]);
    }
});

const selectDelivery = (item) => {
    selectedDelivery.value = item;
}

watch(() => cloneDeep(filter.value), throttle(() => {
    router.get(route('mixpost.webhooks.deliveries.index', {
        workspace: workspaceCtx.id,
        webhook: props.webhook.id
    }), pickBy(filter.value), {
        preserveState: true,
        preserveScroll: true,
        only: ['deliveries', 'filter']
    });
}, 300))
</script>
<template>
    <Head :title="$t('webhook.deliveries')"/>

    <div class="w-full mx-auto row-py">
        <PageHeader :title="$t('webhook.deliveries')">
            <template #description>
                {{ webhook.name }}
                <div class="text-gray-500">
                    {{ webhook.callback_url }}
                </div>
            </template>

            <WebhookAction :record="webhook" :create="false" :deliveries="false"/>
        </PageHeader>

        <div class="row-px">
            <div class="w-full mt-lg">
                <Tabs>
                    <Tab @click="filter.status = null" :active="!$page.props.filter.status">{{
                            $t('general.all')
                        }}
                    </Tab>
                    <Tab @click="filter.status = 'success'" :active="$page.props.filter.status === 'success'">
                        {{ $t("general.succeeded") }}
                    </Tab>
                    <Tab @click="filter.status = 'error'" :active="$page.props.filter.status === 'error'">
                        {{ $t("general.failed") }}
                    </Tab>
                </Tabs>
            </div>

            <Panel class="mt-lg" :with-padding="false">
                <Flex gap="gap-0">
                    <div class="w-full md:w-1/2 border-r border-gray-100">
                        <template v-for="item in deliveries.data" :key="item.id">
                            <WebhookDeliveryItem
                                :item="item"
                                :active="selectedDelivery && selectedDelivery.id === item.id"
                                @click="selectDelivery(item)"/>
                        </template>

                        <NoResult v-if="!deliveries.meta.total" class="py-md px-md"/>
                    </div>

                    <div class="w-full md:w-1/2">
                        <template v-if="selectedDelivery">
                            <WebhookDeliveryItemView :webhookId="webhook.id" :delivery="selectedDelivery"/>
                        </template>
                    </div>
                </Flex>
            </Panel>

            <div v-if="deliveries.meta.links.length > 3" class="mt-lg">
                <Pagination :meta="deliveries.meta" :links="deliveries.links"/>
            </div>
        </div>
    </div>
</template>
