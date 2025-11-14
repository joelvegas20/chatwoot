<script setup>
import { onMounted } from 'vue';

import AgentTable from './overview/AgentTable.vue';
import MetricCard from './overview/MetricCard.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';

const store = useStore();

const uiFlags = useMapGetter('getOverviewUIFlags');
const agentConversationMetric = useMapGetter('getAgentConversationMetric');
const agents = useMapGetter('agents/getAgents');

const fetchData = () => store.dispatch('fetchAgentConversationMetric');

const { startRefetching } = useLiveRefresh(fetchData); // eslint-disable-line no-unused-vars

onMounted(() => {
  store.dispatch('agents/get');
  fetchData();
  // startRefetching(); // Temporarily disabled to prevent freezing
});
</script>

<template>
  <div class="flex flex-row flex-wrap max-w-full">
    <MetricCard :header="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.HEADER')">
      <AgentTable
        :agents="agents"
        :agent-metrics="agentConversationMetric"
        :is-loading="uiFlags.isFetchingAgentConversationMetric"
      />
    </MetricCard>
  </div>
</template>
