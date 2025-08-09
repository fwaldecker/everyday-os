<script setup>
import {defineAsyncComponent} from "vue";
import EmojiPicker from "@/Components/Package/EmojiPicker.vue";
import Flex from "../Layout/Flex.vue";
const AIAssist = defineAsyncComponent(() => import("@/Components/AI/Text/AIAssist.vue"));

const props = defineProps({
    editor: {
        required: true,
        type: Object
    },
    text: {
        required: false,
        type: String
    }
});
</script>
<template>
    <Flex>
        <EmojiPicker
            @selected="(emoji) => editor.commands.insertContent(emoji.native)"
        />

        <template v-if="$page.props.ai_is_ready_to_use">
            <AIAssist
                @insert="(value) => editor.commands.insertContent(value)"
                @replace="(value) => {editor.commands.clearContent(); editor.commands.insertContent(value)}"
                :text="text"/>
        </template>
    </Flex>
</template>
