<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

defineProps({
  keepAlive: {
    type: Boolean,
    default: true,
  },
});

const route = useRoute();
const isSidebarAppView = computed(() => route.name === 'sidebar_app_view');
</script>

<template>
  <div
    class="flex flex-col w-full m-0 overflow-auto bg-n-background font-inter"
    :class="
      isSidebarAppView
        ? 'p-0 min-h-screen h-screen'
        : 'h-full p-6 sm:py-8 lg:px-16'
    "
  >
    <div
      class="flex items-start w-full"
      :class="isSidebarAppView ? '' : 'max-w-6xl mx-auto'"
    >
      <router-view v-slot="{ Component }">
        <keep-alive v-if="keepAlive">
          <component :is="Component" />
        </keep-alive>
        <component :is="Component" v-else />
      </router-view>
    </div>
  </div>
</template>
