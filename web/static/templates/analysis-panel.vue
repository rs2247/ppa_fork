<template>
  <div class="container-fluid" style="position: relative;">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Gerador de Apresentações
        </h2>
      </div>
    </div>

    <div class="row">
      <div class="transparent-loader" v-if="loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-6">
        <label>APRESENTAÇÃO</label>
        <multiselect v-model="analysisType" :options="analysisOptions" :allowEmpty="false" label="name" track-by="key" placeholder="Selecione a apresentação" selectLabel="" deselectLabel=""></multiselect>
      </div>

      <div class="col-md-6">
      </div>
    </div>

    <template v-if="analysisType && analysisType.key == 'ies'">
      <ies-analysis
        ref="iesFilter"
        :semester-start="semesterStart"
        :semester-end="semesterEnd"
        :university-options="universityOptions"
        :location-options="locationOptions"
        :regions-options="regionsOptions"
        :states-options="statesOptions"
        :kind-options="kindOptions"
        :level-options="levelOptions"
        :cities-options="citiesOptions"
        :campus-options="campusOptions">
      </ies-analysis>
    </template>
    <template v-if="analysisType && analysisType.key == 'semester_end'">
      <semester-end-analysis
        ref="semesterEndFilter"
        :semester-start="semesterStart"
        :semester-end="semesterEnd"
        :university-options="universityOptions"
        :university-group-options="universityGroupOptions"
        :location-options="locationOptions"
        :regions-options="regionsOptions"
        :states-options="statesOptions"
        :kind-options="kindOptions"
        :level-options="levelOptions"
        :cities-options="citiesOptions"
        :campus-options="campusOptions">
      </semester-end-analysis>
    </template>

    <template v-if="analysisType && analysisType.key == 'partial_presentation'">
      <partial-presentation-analysis
        ref="partialPresentationFilter"
        :semester-start="semesterStart"
        :semester-end="semesterEnd"
        :university-options="universityOptions"
        :university-group-options="universityGroupOptions"
        :location-options="locationOptions"
        :regions-options="regionsOptions"
        :states-options="statesOptions"
        :kind-options="kindOptions"
        :level-options="levelOptions"
        :cities-options="citiesOptions"
        :campus-options="campusOptions">
      </partial-presentation-analysis>
    </template>

    <template v-if="analysisType && analysisType.key == 'qap_presentation'">
      <qap-presentation
        ref="qapPresentationFilter"
        :university-options="universityOptions"
        :kind-options="kindOptions"
        :level-options="levelOptions">
      </qap-presentation>
    </template>

    <div class="row">
      <div class="col-md-12 default-margin-top">
        <button class="btn-submit" @click="execute">
          Executar
        </button>
      </div>
    </div>

    <iframe id="download_frame" src="about:blank" style="display: none;"></iframe>
  </div>
</template>

<script>
import _ from 'lodash'
import Multiselect from 'vue-multiselect'
import Authentication from "../js/components/authentication";
import MessageDialog from '../js/components/message-dialog';
import IesAnalysis from './analysis/ies-analysis-filter';
import SemesterEndAnalysis from './analysis/semester-end-analysis-filter';
import PartialPresentationAnalysis from './analysis/partial-presentation-analysis-filter';
import QapPresentation from './analysis/qap-presentation-filter';
import moment from 'moment';

export default {
  data() {
    return {
      semesterStart: null,
      semesterEnd: null,
      kindOptions: [],
      levelOptions: [],
      locationOptions: [],
      regionsOptions: [],
      statesOptions: [],
      citiesOptions: [],
      campusOptions: [],
      loading: false,
      analysisType: null,
      universityOptions: [],
      universityGroupOptions: [],
      analysisOptions: [
        { name: 'Taxas e Indicadores da IES', key: 'ies' },
        { name: 'Apresentação parcial', key: 'partial_presentation' },
        //{ name: 'Apresentação de final de semestre', key: 'semester_end' },
        //{ name: 'Cursos mais buscados, mais vendidos, e offered médio vendido', key: 'stock' },
        //{ name: 'Fluxo de Concorrência', key: 'flow' },
        //{ name: 'Precificação', key: 'pricing' },
      ]
    }
  },
  components: {
    Multiselect,
    IesAnalysis,
    SemesterEndAnalysis,
    PartialPresentationAnalysis,
    QapPresentation,
  },
  mounted() {
    console.log("mounted");
    AnalysisChannel.on('analysisData', (payload) => this.receiveAnalysis(payload));
    AnalysisChannel.on('analysisError', (payload) => this.receiveAnalysisError(payload));

    //podem ser reutilizados pelo componente que esta sendo usado no momento
    AnalysisChannel.on('citiesFilterData', (payload) => this.receiveCitiesFilterData(payload));
    AnalysisChannel.on('campusFilterData', (payload) => this.receiveCampusFilterData(payload));

    this.loading = true;
    this.loadFilters();

    let currentCapturePeriod = document.getElementById("capture-period").value;


    //TODO! como resolver o periodo atual? ( precisa? talvez precise! )
    //se eh  atual -> apresentacao parcial
    if (currentCapturePeriod == 8) {
      this.analysisOptions.push({ name: 'Apresentação parcial', key: 'partial_presentation' });
    }

    //se eh menor que o atual -> final de semestre ( mas as vezes tb quer ver a de final de semestre no semestre atual!)
    if (currentCapturePeriod < 8) {
      this.analysisOptions.push({ name: 'Apresentação de final de semestre', key: 'semester_end' });
    }

    // this.analysisOptions.push({ name: 'Apresentação QAP', key: 'qap_presentation' });
  },
  methods: {
    receiveCitiesFilterData(data){
      this.citiesOptions = data.cities;
      console.log("receiveCitiesFilterData");
    },
    receiveCampusFilterData(data){
      this.campusOptions = data.campus;
      console.log("receiveCampusFilterData");
    },
    loadFilters() {
      AnalysisChannel.push('loadFilters').receive('ok', (data) => {
        this.semesterStart = data.semesterStart;
        this.semesterEnd = data.semesterEnd;

        this.regionsOptions = data.regions;
        this.statesOptions = data.states;
        this.kindOptions = data.kinds;
        this.levelOptions = data.levels;
        this.locationOptions = data.locationTypes;
        this.universityOptions = data.universities;
        this.universityGroupOptions = data.groups;
        this.loading = false;
      })
    },
    reportParameters()  {
      if (this.analysisType.key == 'ies') {
        return this.$refs.iesFilter.filterData();
      } else if (this.analysisType.key == 'semester_end') {
        return this.$refs.semesterEndFilter.filterData();
      } else if (this.analysisType.key == 'partial_presentation') {
        return this.$refs.partialPresentationFilter.filterData();
      } else if (this.analysisType.key == 'qap_presentation') {
        return this.$refs.qapPresentationFilter.filterData();
      }
    },
    receiveAnalysis(data) {
      console.log("receiveAnalysis: data: " + JSON.stringify(data));
      this.loading = false;
      const dialog = new MessageDialog("global-dialog", "success", "Ok");
      dialog.show("Análise finalizada");
      document.getElementById("download_frame").setAttribute('src', `/download_analysis?filename=${data.filename}&name=${data.download_name}`);
    },
    receiveAnalysisError(data) {
      const dialog = new MessageDialog("global-dialog", "danger", "Erro");
      dialog.show("Erro ao gerar análise");
      this.loading = false;
    },
    validateParameters() {
      if (this.analysisType.key == 'ies') {
        return this.$refs.iesFilter.validateParameters();
      } else if (this.analysisType.key == 'semester_end') {
        return this.$refs.semesterEndFilter.validateParameters();
      } else if (this.analysisType.key == 'partial_presentation') {
        return this.$refs.partialPresentationFilter.validateParameters();
      } else if (this.analysisType.key == 'qap_presentation') {
        return this.$refs.qapPresentationFilter.validateParameters();
      }
      return false;
    },
    execute() {
      if (_.isNil(this.analysisType)) {
        alert("Selecione uma análise");
        return;
      }
      if (!this.validateParameters()) {
        return;
      }
      this.loading = true;
      AnalysisChannel.push('generate', { type: this.analysisType.key, parameters: this.reportParameters() }).receive('timeout', () => {
        console.log("generate timeout");
      })
    }
  }
}
</script>
