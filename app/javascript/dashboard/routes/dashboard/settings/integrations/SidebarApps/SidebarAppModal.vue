<script>
import { useVuelidate } from '@vuelidate/core';
import { required, helpers } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mode: {
      type: String,
      default: 'create',
    },
    selectedAppData: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  validations: {
    app: {
      title: { required },
      content: {
        type: { required },
        url: {
          required,
          url: helpers.withMessage(
            'A valid URL is required',
            helpers.regex(/^https?:\/\/|^http:\/\/localhost/)
          ),
        },
      },
    },
  },
  data() {
    return {
      isLoading: false,
      app: {
        title: '',
        icon: 'i-lucide-app-window',
        visible: true,
        content: {
          type: 'frame',
          url: '',
        },
      },
    };
  },
  computed: {
    header() {
      return this.$t(`INTEGRATION_SETTINGS.SIDEBAR_APPS.${this.mode}.HEADER`);
    },
    submitButtonLabel() {
      return this.$t(
        `INTEGRATION_SETTINGS.SIDEBAR_APPS.${this.mode}.FORM_SUBMIT`
      );
    },
  },
  mounted() {
    if (this.mode === 'UPDATE' && this.selectedAppData) {
      this.app.title = this.selectedAppData.title;
      this.app.icon = this.selectedAppData.icon;
      this.app.visible = this.selectedAppData.visible;
      this.app.content = this.selectedAppData.content[0];
    }
  },
  methods: {
    closeModal() {
      // Reset the data once closed
      this.app = {
        title: '',
        icon: 'i-lucide-app-window',
        visible: true,
        content: { type: 'frame', url: '' },
      };
      this.$emit('close');
    },
    async submit() {
      try {
        this.v$.$touch();
        if (this.v$.$invalid) {
          return;
        }

        const action = this.mode.toLowerCase();
        const payload = {
          title: this.app.title,
          icon: this.app.icon,
          visible: this.app.visible,
          content: [this.app.content],
        };

        if (action === 'update') {
          payload.id = this.selectedAppData.id;
        }

        this.isLoading = true;
        await this.$store.dispatch(`sidebarApps/${action}`, payload);
        useAlert(
          this.$t(`INTEGRATION_SETTINGS.SIDEBAR_APPS.${this.mode}.API_SUCCESS`)
        );
        this.closeModal();
      } catch (err) {
        useAlert(
          this.$t(`INTEGRATION_SETTINGS.SIDEBAR_APPS.${this.mode}.API_ERROR`)
        );
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <woot-modal :show="show" :on-close="closeModal">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="header" />
      <form class="w-full" @submit.prevent="submit">
        <woot-input
          v-model="app.title"
          :class="{ error: v$.app.title.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.TITLE_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.TITLE_PLACEHOLDER')
          "
          :error="
            v$.app.title.$error
              ? $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.TITLE_ERROR')
              : null
          "
          data-testid="app-title"
          @input="v$.app.title.$touch"
          @blur="v$.app.title.$touch"
        />
        <woot-input
          v-model="app.icon"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.ICON_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.ICON_PLACEHOLDER')
          "
          data-testid="app-icon"
        />
        <woot-input
          v-model="app.content.url"
          :class="{ error: v$.app.content.url.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.URL_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.URL_PLACEHOLDER')
          "
          :error="
            v$.app.content.url.$error
              ? $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.URL_ERROR')
              : null
          "
          data-testid="app-url"
          @input="v$.app.content.url.$touch"
          @blur="v$.app.content.url.$touch"
        />
        <div class="flex items-center">
          <input
            id="app-visible"
            v-model="app.visible"
            type="checkbox"
            class="mr-2"
          />
          <label for="app-visible">
            {{ $t('INTEGRATION_SETTINGS.SIDEBAR_APPS.FORM.VISIBLE_LABEL') }}
          </label>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('INTEGRATION_SETTINGS.SIDEBAR_APPS.CREATE.FORM_CANCEL')"
            @click.prevent="closeModal"
          />
          <NextButton
            type="submit"
            :label="submitButtonLabel"
            :disabled="v$.$invalid"
            :is-loading="isLoading"
          />
        </div>
      </form>
    </div>
  </woot-modal>
</template>
