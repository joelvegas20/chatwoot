<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

const route = useRoute();
const sidebarApps = useMapGetter('sidebarApps/getRecords');

const appId = computed(() => parseInt(route.params.appId, 10));
const currentApp = computed(() =>
  sidebarApps.value.find(app => app.id === appId.value)
);

onMounted(() => {
  // Component mounted
});
</script>

<template>
  <div class="flex flex-col w-full h-screen">
    <div class="flex items-center justify-between p-4 border-b border-n-weak">
      <div class="flex items-center gap-3">
        <i :class="currentApp?.icon || 'i-lucide-app-window'" class="size-5" />
        <h1 class="text-lg font-semibold text-n-slate-12">
          {{ currentApp?.title || 'Sidebar App' }}
        </h1>
      </div>
    </div>

    <div class="flex-1 overflow-hidden">
      <iframe
        v-if="currentApp"
        :src="currentApp.content[0]?.url"
        width="100%"
        height="100%"
        class="border-0"
        :title="currentApp.title"
        allowfullscreen
      />
      <div
        v-else
        class="flex items-center justify-center h-full text-n-slate-11"
      >
        {{ $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.APP_NOT_FOUND') }}
      </div>
    </div>
  </div>
</template>
