<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Modal from '../../../../components/Modal.vue';

export default {
  components: {
    NextButton,
    Modal,
    WootMessageEditor,
  },
  props: {
    onClose: { type: Function, default: () => {} },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      newCanned: {
        showAlert: false,
        showLoading: false,
      },
      shortCode: '',
      content: '',
      inboxes: [],
      selectedInbox: null,
      selectedCategory: 'UTILITY',
      metaCategories: [
        { value: 'MARKETING', label: 'Marketing' },
        { value: 'UTILITY', label: 'Utility' },
        { value: 'AUTHENTICATION', label: 'Authentication' },
      ],
      show: true,
    };
  },
  validations: {
    shortCode: {
      required,
      minLength: minLength(2),
    },
    content: {
      required,
    },
  },
  computed: {
    isWhatsappInbox() {
      return this.selectedInbox?.channel_type === 'Channel::Whatsapp';
    },
  },
  mounted() {
    this.fetchInboxes();
  },
  methods: {
    async fetchInboxes() {
      try {
        if (!this.$store.getters['inboxes/getInboxes'].length) {
          await this.$store.dispatch('inboxes/get');
        }
        this.inboxes = this.$store.getters['inboxes/getInboxes'];
      } catch (error) {
        const errorMessage =
          error?.message || this.$t('INBOXES.FETCH.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
    setPageName({ name }) {
      this.v$.content.$touch();
      this.content = name;
    },
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.selectedInbox = null;
      this.selectedCategory = 'UTILITY';
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    async createCannedResponse() {
      this.newCanned.showLoading = true;

      try {
        await this.$store.dispatch('createCannedResponse', {
          short_code: this.shortCode,
          content: this.content,
          inbox_id: this.selectedInbox?.id,
          canned_type: this.isWhatsappInbox ? 'whatsapp' : 'generic',
          category: this.selectedCategory,
        });

        this.newCanned.showLoading = false;
        useAlert(this.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.resetForm();
        setTimeout(() => {
          this.onClose();
        }, 10);
      } catch (error) {
        this.newCanned.showLoading = false;
        const errorMessage =
          error?.message || this.$t('CANNED_MGMT.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('CANNED_MGMT.ADD.TITLE')" />
      <form class="flex flex-col w-full" @submit.prevent="createCannedResponse">
        <div class="field">
          <label for="inbox">
            {{ $t('CANNED_MGMT.ADD.FORM.INBOX.LABEL') }}
          </label>
          <select id="inbox" v-model="selectedInbox" class="input">
            <option disabled value="">
              {{ $t('CANNED_MGMT.ADD.FORM.INBOX.PLACEHOLDER') }}
            </option>
            <option v-for="inbox in inboxes" :key="inbox.id" :value="inbox">
              {{ inbox.name }} ({{ inbox.channel_type }})
            </option>
          </select>
        </div>
        <div v-if="isWhatsappInbox" class="mt-4">
          <label
            for="category"
            class="block text-sm font-medium text-gray-700 mb-1"
          >
            {{ $t('CANNED_MGMT.ADD.FORM.TEMPLATE_CATEGORY.LABEL') }}
          </label>
          <select
            id="category"
            v-model="selectedCategory"
            class="w-full border border-gray-300 rounded-md px-3 py-2"
          >
            <option disabled value="">
              {{ $t('CANNED_MGMT.ADD.FORM.TEMPLATE_CATEGORY.PLACEHOLDER') }}
            </option>
            <option
              v-for="category in metaCategories"
              :key="category.value"
              :value="category.value"
            >
              {{ category.label }}
            </option>
          </select>
        </div>
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.CONTENT.PLACEHOLDER')"
              @blur="v$.content.$touch"
            />
          </div>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            type="submit"
            :label="$t('CANNED_MGMT.ADD.FORM.SUBMIT')"
            :disabled="
              v$.content.$invalid ||
              v$.shortCode.$invalid ||
              newCanned.showLoading
            "
            :is-loading="newCanned.showLoading"
          />
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
:deep(.ProseMirror-menubar) {
  @apply hidden;
}

:deep(.ProseMirror-woot-style) {
  @apply min-h-[12.5rem];

  p {
    @apply text-base;
  }
}
</style>
