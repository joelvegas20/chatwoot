<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SidebarAppModal from './SidebarAppModal.vue';
import SidebarAppsRow from './SidebarAppsRow.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BaseSettingsHeader,
    SidebarAppModal,
    SidebarAppsRow,
    NextButton,
  },
  data() {
    return {
      loading: {},
      showSidebarAppPopup: false,
      showDeleteConfirmationPopup: false,
      selectedApp: {},
      mode: 'CREATE',
    };
  },
  computed: {
    ...mapGetters({
      records: 'sidebarApps/getRecords',
      uiFlags: 'sidebarApps/getUIFlags',
    }),
    tableHeaders() {
      return [
        this.$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.LIST.TABLE_HEADER.NAME'),
        this.$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.LIST.TABLE_HEADER.ENDPOINT'),
        this.$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.LIST.TABLE_HEADER.VISIBLE'),
      ];
    },
  },
  mounted() {
    this.$store.dispatch('sidebarApps/get');
  },
  methods: {
    toggleSidebarAppPopup() {
      this.showSidebarAppPopup = !this.showSidebarAppPopup;
      this.selectedApp = {};
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedApp = response;
    },
    openCreatePopup() {
      this.mode = 'CREATE';
      this.selectedApp = {};
      this.showSidebarAppPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    editApp(app) {
      this.loading[app.id] = true;
      this.mode = 'UPDATE';
      this.selectedApp = app;
      this.showSidebarAppPopup = true;
    },
    confirmDeletion() {
      this.loading[this.selectedApp.id] = true;
      this.closeDeletePopup();
      this.deleteApp(this.selectedApp.id);
    },
    async deleteApp(id) {
      try {
        await this.$store.dispatch('sidebarApps/delete', id);
        useAlert(
          this.$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DELETE.API_SUCCESS')
        );
      } catch (error) {
        useAlert(this.$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DELETE.API_ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 gap-8 overflow-auto">
    <BaseSettingsHeader
      :title="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.TITLE')"
      :description="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DESCRIPTION')"
      :link-text="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.LEARN_MORE')"
      feature-name="sidebar_apps"
      :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
    >
      <template #actions>
        <NextButton
          icon="i-lucide-circle-plus"
          :label="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.HEADER_BTN_TXT')"
          @click="openCreatePopup"
        />
      </template>
    </BaseSettingsHeader>
    <div class="w-full overflow-x-auto text-n-slate-11">
      <p
        v-if="!uiFlags.isFetching && !records.length"
        class="flex flex-col items-center justify-center h-full"
      >
        {{ $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.LIST.404') }}
      </p>
      <woot-loading-state
        v-if="uiFlags.isFetching"
        :message="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.LIST.LOADING')"
      />
      <table
        v-if="!uiFlags.isFetching && records.length"
        class="min-w-full divide-y divide-n-weak"
      >
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 ltr:pr-4 rtl:pl-4 font-semibold text-left text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="divide-y divide-n-weak">
          <SidebarAppsRow
            v-for="(sidebarAppItem, index) in records"
            :key="sidebarAppItem.id"
            :index="index"
            :app="sidebarAppItem"
            @edit="editApp"
            @delete="openDeletePopup"
          />
        </tbody>
      </table>
    </div>

    <SidebarAppModal
      v-if="showSidebarAppPopup"
      :show="showSidebarAppPopup"
      :mode="mode"
      :selected-app-data="selectedApp"
      @close="toggleSidebarAppPopup"
    />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DELETE.TITLE')"
      :message="
        $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DELETE.MESSAGE', {
          appName: selectedApp.title,
        })
      "
      :confirm-text="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DELETE.CONFIRM_YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.DELETE.CONFIRM_NO')"
    />
  </div>
</template>
