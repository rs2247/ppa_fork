<template>
  <div :id="'modal-dialog-' + identification" class="modal" role="dialog" style="z-index: 5000;">
    <div class="modal-dialog">
      <div class="modal-content" style="background-color: #1F2426;">
        <div class="transparent-loader" v-if="loading">
          <div class="loader"></div>
        </div>
        <slot></slot>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      loading: false,
    }
  },
  props: ['identification'],
  methods: {
    setLoader() {
      this.loading = true;
    },
    resetLoader() {
      this.loading = false;
    },
    show() {
      $('#modal-dialog-' + this.identification).modal('show');
    },
    close() {
      $('#modal-dialog-' + this.identification).modal('hide');
    },
  }
}

</script>
