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
    id: { type: Number, default: null },
    edcontent: { type: String, default: '' },
    edshortCode: { type: String, default: '' },
    edinboxId: { type: Number, default: null },
    edcategory: { type: String, default: 'UTILITY' },
    onClose: { type: Function, default: () => {} },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      editCanned: {
        showAlert: false,
        showLoading: false,
      },
      shortCode: this.edshortCode,
      content: this.edcontent,
      inboxes: [],
      selectedInbox: null,
      selectedCategory: this.edcategory,
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
    pageTitle() {
      return `${this.$t('CANNED_MGMT.EDIT.TITLE')} - ${this.edshortCode}`;
    },
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
        this.selectedInbox = this.inboxes.find(
          inbox => inbox.id === this.edinboxId
        );
      } catch (error) {
        const errorMessage =
          error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
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
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    async editCannedResponse() {
      this.editCanned.showLoading = true;

      try {
        await this.$store.dispatch('updateCannedResponse', {
          id: this.id,
          short_code: this.shortCode,
          content: this.content,
          inbox_id: this.selectedInbox?.id,
          category: this.selectedCategory,
        });
        this.editCanned.showLoading = false;
        useAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.resetForm();
        setTimeout(() => {
          this.onClose();
        }, 10);
      } catch (error) {
        this.editCanned.showLoading = false;
        const errorMessage =
          error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="pageTitle" />
      <form class="flex flex-col w-full" @submit.prevent="editCannedResponse">
        <div class="field">
          <label for="inbox">
            {{ $t('CANNED_MGMT.EDIT.FORM.INBOX.LABEL') }}
          </label>
          <select id="inbox" v-model="selectedInbox" class="input">
            <option disabled value="">
              {{ $t('CANNED_MGMT.EDIT.FORM.INBOX.PLACEHOLDER') }}
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
            {{ $t('CANNED_MGMT.EDIT.FORM.TEMPLATE_CATEGORY.LABEL') }}
          </label>
          <select
            id="category"
            v-model="selectedCategory"
            class="w-full border border-gray-300 rounded-md px-3 py-2"
          >
            <option disabled value="">
              {{ $t('CANNED_MGMT.EDIT.FORM.INBOX.PLACEHOLDER') }}
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
            {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
              @blur="v$.content.$touch"
            />
          </div>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            type="submit"
            :label="$t('CANNED_MGMT.EDIT.FORM.SUBMIT')"
            :disabled="
              v$.content.$invalid ||
              v$.shortCode.$invalid ||
              editCanned.showLoading
            "
            :is-loading="editCanned.showLoading"
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
