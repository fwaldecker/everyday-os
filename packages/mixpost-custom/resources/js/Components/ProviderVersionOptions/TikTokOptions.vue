<script setup>
import {computed, onBeforeUnmount, onMounted, watch} from "vue";
import {useI18n} from "vue-i18n";
import {clone, get} from "lodash";
import usePostValidator from "../../Composables/usePostValidator";
import Select from "@/Components/Form/Select.vue";
import ProviderOptionWrap from "@/Components/ProviderVersionOptions/ProviderOptionWrap.vue";
import Label from "@/Components/Form/Label.vue";
import HorizontalGroup from "../Layout/HorizontalGroup.vue";
import Checkbox from "../Form/Checkbox.vue";
import OptionGroup from "./OptionGroup.vue";
import Alert from "../Util/Alert.vue";
import Switch from "../Form/Switch.vue";
import VerticalGroup from "../Layout/VerticalGroup.vue";
import Flex from "../Layout/Flex.vue";
import Exclamation from "../../Icons/Exclamation.vue";

const {t: $t} = useI18n()

const props = defineProps(['options', 'accounts', 'activeVersion'])

const MUSIC_TERMS_URL = 'https://www.tiktok.com/legal/page/global/music-usage-confirmation/en';
const BRAND_TERMS_URL = 'https://www.tiktok.com/legal/page/global/bc-policy/en';

const {addAccountError, removeAccountError, removeError} = usePostValidator();

const availableAccounts = computed(() => {
    if (props.activeVersion === 0) {
        return props.accounts;
    }

    return props.accounts.filter(account => account.id === props.activeVersion);
});

const setDefaultValues = () => {
    availableAccounts.value.forEach((account) => {
        const value = get(props.options.privacy_level, `account-${account.id}`);

        if (!value) {
            // props.options.privacy_level[`account-${account.id}`] = account.data.is_private ? 'FOLLOWER_OF_CREATOR' : 'PUBLIC_TO_EVERYONE';

            props.options.allow_comments[`account-${account.id}`] = false;
            props.options.allow_duet[`account-${account.id}`] = false;
            props.options.allow_stitch[`account-${account.id}`] = false;
            props.options.content_disclosure[`account-${account.id}`] = false;
            props.options.brand_organic_toggle[`account-${account.id}`] = false;
            props.options.brand_content_toggle[`account-${account.id}`] = false;
        }
    })
}

const accountPrivacyLevelOptions = (account) => {
    if (!Array.isArray(account.data.privacy_levels)) {
        return [];
    }

    const privacyLevels = clone(account.data.privacy_levels);

    return privacyLevels.map((option) => {
        const names = {
            'PUBLIC_TO_EVERYONE': $t('service.tiktok.everyone'),
            'MUTUAL_FOLLOW_FRIENDS': $t('service.tiktok.friends'),
            'SELF_ONLY': $t('service.tiktok.only_you'),
            'FOLLOWER_OF_CREATOR': $t('service.tiktok.followers')
        }

        return {
            key: option,
            name: names.hasOwnProperty(option) ? names[option] : option,
        }
    })
}

const getAccountPrivacyLevel = (account) => {
    return props.options.privacy_level[`account-${account.id}`];
}

const getContentDisclosure = (account) => {
    return props.options.content_disclosure[`account-${account.id}`];
}

const getBrandOrganicToggle = (account) => {
    return props.options.brand_organic_toggle[`account-${account.id}`];
}

const getBrandContentToggle = (account) => {
    return props.options.brand_content_toggle[`account-${account.id}`];
}

const getPrompt = (account) => {
    const brandOrganicToggle = props.options.brand_organic_toggle[`account-${account.id}`];
    const brandContentToggle = props.options.brand_content_toggle[`account-${account.id}`];

    if (brandOrganicToggle && brandContentToggle) {
        return $t('service.tiktok.partner_video_alert');
    }

    if (brandOrganicToggle && !brandContentToggle) {
        return $t('service.tiktok.promo_video_alert');
    }

    if (brandContentToggle) {
        return $t('service.tiktok.partner_video_alert');
    }

    return null;
}

const isPrivacySelfOnlyDisabled = (account) => {
    return props.options.content_disclosure[`account-${account.id}`] && props.options.brand_content_toggle[`account-${account.id}`];
}

const isBrandContentToggleDisabled = (account) => {
    const level = getAccountPrivacyLevel(account);

    return !level || level === 'SELF_ONLY';
}

const onPrivacyLevelChange = (account) => {
    validatePrivacyLevel(account);

    if (isBrandContentToggleDisabled(account)) {
        props.options.brand_content_toggle[`account-${account.id}`] = false;
    }
}

const validateContentDisclosure = (account) => {
    if (getContentDisclosure(account) && (!getBrandOrganicToggle(account) && !getBrandContentToggle(account))) {
        addAccountError({
            group: 'tik_tok',
            key: `content_disclosure`,
            message: $t('service.tiktok.content_disclosure_required'),
            accountId: account.id,
            accountName: account.name,
            providerName: account.provider_name,
        })

        return;
    }

    removeAccountError({
        group: 'tik_tok',
        key: `content_disclosure`,
        accountId: account.id,
    });
}

const validatePrivacyLevel = (account) => {
    if (!getAccountPrivacyLevel(account)) {
        addAccountError({
            group: 'tik_tok',
            key: `privacy_level`,
            message: $t('service.tiktok.privacy_level_required'),
            accountId: account.id,
            accountName: account.name,
            providerName: account.provider_name,
        })
        return;
    }

    removeAccountError({
        group: 'tik_tok',
        key: `privacy_level`,
        accountId: account.id,
    });
}

const clearErrors = () => {
    removeError({
        group: 'tik_tok',
    });
}

const validate = () => {
    availableAccounts.value.forEach((account) => {
        validatePrivacyLevel(account);
        validateContentDisclosure(account);
    })
}

watch(() => props.accounts, () => {
    setDefaultValues();
    clearErrors();
    validate();
});

onMounted(() => {
    validate();
});

onBeforeUnmount(() => {
    clearErrors();
});
</script>
<template>
    <ProviderOptionWrap :title="$t('service.provider_options', {provider: 'TikTok'})" provider="tiktok">
        <template v-for="account in availableAccounts" :key="account.id">
            <OptionGroup>
                <template #title>{{ account.name }}</template>

                <!--Privacy level-->
                <div class="w-full">
                    <Label :for="`privacy_level-${account.id}`">{{ $t('service.tiktok.who_watch_video') }}</Label>
                    <Select v-model="options.privacy_level[`account-${account.id}`]"
                            @change="onPrivacyLevelChange(account)"
                            :id="`privacy_level-${account.id}`">
                        <option v-for="level in accountPrivacyLevelOptions(account)"
                                :value="level.key"
                                :key="level.key"
                                :disabled="level.key === 'SELF_ONLY' && isPrivacySelfOnlyDisabled(account)"
                        >
                            {{ level.name }}
                            <template v-if="level.key === 'SELF_ONLY' && isPrivacySelfOnlyDisabled(account)">
                                ({{ $t('service.tiktok.branded_no_private') }})
                            </template>
                        </option>
                    </Select>
                </div>

                <!--Privacy settings-->
                <VerticalGroup class="mt-md">
                    <template #title>{{ $t('service.tiktok.allow_users') }}</template>

                    <Flex gap="gap-md" class="md:items-center">
                        <Label :for="`allow_comments-${account.id}`" class="mb-0!">
                            <Checkbox v-model:checked="options.allow_comments[`account-${account.id}`]"
                                      :disabled="account.data.comment_disabled"
                                      :id="`allow_comments-${account.id}`"/>
                            {{ $t('service.tiktok.comment') }}
                        </Label>

                        <Label :for="`allow_duet-${account.id}`" class="mb-0!">
                            <Checkbox v-model:checked="options.allow_duet[`account-${account.id}`]"
                                      :disabled="account.data.duet_disabled"
                                      :id="`allow_duet-${account.id}`"/>
                            {{ $t('service.tiktok.duet') }}
                        </Label>

                        <Label :for="`allow_stitch-${account.id}`" class="mb-0!">
                            <Checkbox v-model:checked="options.allow_stitch[`account-${account.id}`]"
                                      :disabled="account.data.stitch_disabled"
                                      :id="`allow_stitch-${account.id}`"/>
                            {{ $t('service.tiktok.stitch') }}
                        </Label>
                    </Flex>
                </VerticalGroup>

                <!--Content disclosure-->
                <div class="mt-md">
                    <HorizontalGroup :flexColMobile="false"
                                     :forceFullWidth="true"
                                     :forceFlexStart="true"
                                     :removeFullWidthFromDefaultSlot="true" class="mt-md">
                        <template #title>
                            <label :for="`content_disclosure-${account.id}`">
                                {{ $t('service.tiktok.disclose') }}
                            </label>
                        </template>

                        <template #description>
                            <span class="text-sm">{{ $t('service.tiktok.disclose_desc') }}</span>
                        </template>

                        <Switch :id="`content_disclosure-${account.id}`"
                                v-model="options.content_disclosure[`account-${account.id}`]"
                                @update:model-value="validateContentDisclosure(account)"
                        />
                    </HorizontalGroup>

                    <template v-if="options.content_disclosure[`account-${account.id}`]">
                        <template v-if="getPrompt(account)">
                            <Alert :closeable="false" class="mt-md">
                                <span>{{ getPrompt(account) }}</span>
                            </Alert>
                        </template>

                        <HorizontalGroup :flexColMobile="false"
                                         :forceFullWidth="true"
                                         :forceFlexStart="true"
                                         :removeFullWidthFromDefaultSlot="true" class="mt-md">
                            <template #title>
                                <label :for="`brand_organic_toggle-${account.id}`">
                                    {{ $t('service.tiktok.your_brand') }}
                                </label>
                            </template>

                            <template #description>
                                <span class="text-sm">{{ $t('service.tiktok.your_brand_desc') }}</span>
                            </template>

                            <Checkbox v-model:checked="options.brand_organic_toggle[`account-${account.id}`]"
                                      :id="`brand_organic_toggle-${account.id}`"
                                      @update:model-value="validateContentDisclosure(account)"
                            />
                        </HorizontalGroup>

                        <HorizontalGroup :flexColMobile="false"
                                         :forceFullWidth="true"
                                         :forceFlexStart="true"
                                         :removeFullWidthFromDefaultSlot="true"
                                         class="mt-md">
                            <template #title>
                                <label :for="`brand_content_toggle-${account.id}`">
                                    {{ $t('service.tiktok.branded_content') }}
                                </label>
                            </template>

                            <template #description>
                                <span class="text-sm">{{ $t('service.tiktok.branded_content_desc') }}</span>

                                <span v-if="isBrandContentToggleDisabled(account)"
                                      class="flex items-center mt-xs text-sm text-orange-600 border border-orange-600 rounded-md p-xs"><Exclamation
                                    class="mr-xs"/>
                                    {{ $t('service.tiktok.visibility_branded_content') }}
                                </span>
                            </template>

                            <Checkbox v-model:checked="options.brand_content_toggle[`account-${account.id}`]"
                                      :disabled="isBrandContentToggleDisabled(account)"
                                      :id="`brand_content_toggle-${account.id}`"
                                      @update:model-value="validateContentDisclosure(account)"
                            />
                        </HorizontalGroup>
                    </template>
                </div>

                <p class="mt-md italic">* {{ $t('post.video_processing_notice') }}</p>

                <!--Terms and conditions-->
                <div class="mt-md">
                    <template
                        v-if="options.content_disclosure[`account-${account.id}`] && options.brand_organic_toggle[`account-${account.id}`] && options.brand_content_toggle[`account-${account.id}`]">
                        <div
                            v-html="$t('service.tiktok.accept_terms', {href_brand: BRAND_TERMS_URL, href_music: MUSIC_TERMS_URL})"/>
                    </template>
                    <template
                        v-else-if="options.content_disclosure[`account-${account.id}`] && options.brand_content_toggle[`account-${account.id}`]">
                        <div
                            v-html="$t('service.tiktok.accept_terms', {href_brand: BRAND_TERMS_URL, href_music: MUSIC_TERMS_URL})"/>
                    </template>
                    <template v-else>
                        <div v-html="$t('service.tiktok.your_brand_accept_terms', {href: MUSIC_TERMS_URL})"/>
                    </template>
                </div>
            </OptionGroup>
        </template>
    </ProviderOptionWrap>
</template>
