<template>
  <date-picker :disabled="disabled" v-model="dateRange" :first-day-of-week="1" :lang="lang" :range="range" :shortcuts="shortcuts" @change="timeRangeSelected" @confirm="timeRangeConfirmed" :not-after="notAfter" :not-before="notBefore" :disabled-days="disabledDays"></date-picker>
</template>

<script>
import DatePicker from 'vue2-datepicker'

export default {
  data() {
    return {
      dateRange: null,
      lang: {
        days: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'],
        months: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
        placeholder: {
          date: 'Data',
          dateRange: 'Período'
        }
      },
    }
  },
  mounted() {
    this.dateRange = this.value;
  },
  watch: {
    value: function (data) {
      this.dateRange = this.value;
    }
  },
  props: {
    value: [Array, Date],
    notAfter: {
      type: Date,
      default: null
    },
    notBefore: {
      type: Date,
      default: null
    },
    disabled: {
      type: Boolean,
      default: false
    },
    range: {
      type: Boolean,
      default: true
    },
    disabledDays: {
      type: Array,
      default: null
    },
    shortcuts: {
      type: Array,
      default: function () {
        return [];
      }
    }
  },
  components: {
    DatePicker,
  },
  methods: {
    timeRangeConfirmed() {
      console.log("timeRangeConfirmed");
    },
    timeRangeSelected() {
      this.$emit('input', this.dateRange);
    }
  }
}
</script>
