<script setup>
import Input from "@/Components/Form/Input.vue";
import ProviderOptionWrap from "@/Components/ProviderVersionOptions/ProviderOptionWrap.vue";
import Radio from "@/Components/Form/Radio.vue";
import HorizontalGroup from "@/Components/Layout/HorizontalGroup.vue";
import Flex from "@/Components/Layout/Flex.vue";
import Label from "@/Components/Form/Label.vue";
import Switch from "@/Components/Form/Switch.vue";
import Textarea from "@/Components/Form/Textarea.vue";
import CallToAction from "@/Components/ProviderVersionOptions/GBP/CallToAction.vue";
import EventTitle from "@/Components/ProviderVersionOptions/GBP/EventTitle.vue";
import StartEndDateTime from "@/Components/ProviderVersionOptions/GBP/StartEndDateTime.vue";

const props = defineProps(['options'])
</script>
<template>
    <ProviderOptionWrap :title="$t('service.provider_options', {provider: 'Google Business Profile'})" provider="gbp">
        <Flex :wrap="false" :responsive="false">
            <label>
                <Radio v-model:checked="options.type" value="post"/>
                {{ $t('service.gbp.post') }}
            </label>
            <label>
                <Radio v-model:checked="options.type" value="offer"/>
                {{ $t('service.gbp.offer') }}
            </label>
            <label>
                <Radio v-model:checked="options.type" value="event"/>
                {{ $t('service.gbp.event') }}
            </label>
        </Flex>

        <div class="mt-md">
            <template v-if="options.type === 'post'">
                <CallToAction :options="options"/>
            </template>

            <template v-if="options.type === 'offer'">
                <EventTitle :options="options" :labelName="$t('service.gbp.offer_title')"/>

                <div class="mt-md md:mt-xs">
                    <StartEndDateTime :options="options"/>
                </div>

                <HorizontalGroup class="mt-md md:mt-xs">
                    <Flex :responsive="false">
                        <Switch id="offer_has_details"
                                v-model="options.offer_has_details"
                        />
                        <Label for="offer_has_details" class="mb-0!">{{ $t('service.gbp.add_more_details') }}</Label>
                    </Flex>
                </HorizontalGroup>

                <template v-if="options.offer_has_details">
                    <HorizontalGroup class="mt-xs">
                        <template #title>
                            <label for="coupon_code">{{ $t('service.gbp.coupon_code') }}</label>
                        </template>

                        <Input v-model="options.coupon_code" id="coupon_code"/>
                    </HorizontalGroup>

                    <HorizontalGroup class="mt-xs">
                        <template #title>
                            <label for="offer_link">{{ $t('service.gbp.offer_link') }}</label>
                        </template>

                        <Input v-model="options.offer_link" id="offer_link" placeholder="https://example.com"/>
                    </HorizontalGroup>

                    <HorizontalGroup class="mt-xs">
                        <template #title>
                            <label for="terms">{{ $t('service.gbp.tos') }}</label>
                        </template>

                        <Textarea v-model="options.terms" id="terms"/>
                    </HorizontalGroup>
                </template>
            </template>

            <template v-if="options.type === 'event'">
                <EventTitle :options="options"/>
                <div class="mt-md md:mt-xs">
                    <StartEndDateTime :options="options" :showTimeFields="true"/>
                </div>
                <div class="mt-xs">
                    <CallToAction :options="options"/>
                </div>
            </template>
        </div>
    </ProviderOptionWrap>
</template>
