<template>
  <div class="container-fluid">

    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          INEP SHARE
        </h2>
      </div>
    </div>

    <div class="panel report-panel panel-default">
      <div class="row" style="position: relative;">
        <div class="transparent-loader" v-if="loadingFilters || loading">
          <div class="loader"></div>
        </div>

        <div class="col-md-12 col-sm-6">
          <panel-primary-filter ref="filter" :filter-options="filterOptions" :university-options="universityOptions" :university-group-options="universityGroupOptions" :deal-owner-options="dealOwnerOptions" :account-type-options="accountTypeOptions" @valueSelected="primaryFilterSelected"></panel-primary-filter>

        </div>

        <div class="col-md-2 col-sm-12 default-margin-top">
          <input type="radio" name="kind" value="1" checked v-model="kindFilter">
          <span style="font-size: 16px;" class="tiny-padding-left">Presencial</span>
          <input type="radio" name="kind" value="3" style="margin-left: 10px;" v-model="kindFilter">
          <span style="font-size: 16px;" class="tiny-padding-left">Ead</span>
        </div>

        <location-filter ref="locationFilter" :location-options="locationOptions" :regions-options="regionsOptions" :states-options="statesOptions" :cities-options="citiesOptions" @cityLocationSelected="loadCities" @locationValueSelected="locationSelected" @locationTypeRemoved="locationRemoved"></location-filter>
      </div>
    </div>

    <div class="panel report-panel panel-default" v-if="data.length > 0">
      <div class="row">
        <ul class="nav navbar-nav justify-content-center">
          <li class="navbar__item" :class="{'active' : showShareTable}">
            <a class="nav-link clickable" @click="showShare">Share</a>
          </li>



          <li class="navbar__item" :class="{'active' : showStatesTable}">
            <a class="nav-link clickable" @click="showStates">Estados</a>
          </li>
          <li class="navbar__item" :class="{'active' : showIESTable}">
            <a class="nav-link clickable" @click="showIES">IESs</a>
          </li>
          <li class="navbar__item" :class="{'active' : showLocationTable}" v-show="hasLocationData">
            <a class="nav-link clickable" @click="showLocation">Praças</a>
          </li>

          <li class="navbar__item" :class="{'active' : showMissingTable}" v-show="hasMissingData">
            <a class="nav-link clickable" @click="showMissing">Estoque faltando</a>
          </li>
        </ul>
      </div>

      <div class="row" style="position: relative;">
        <div class="transparent-loader" v-if="loading">
          <div class="loader"></div>
        </div>

        <div class="col-md-12" v-show="showShareTable">
          <div class="panel report-panel panel-default" v-if="loadingInepData || stockInepData">
            <div class="row">
              <div class="transparent-loader" v-if="loadingInepData">
                <div class="loader"></div>
              </div>
              <div class="col-md-12">
                <table class="data-table" width="100%">
                  <thead>
                    <tr>
                      <th colspan="9">20 Cursos mais vendidos
                        <span class="glyphicon glyphicon-info-sign tooltip__icon">
                          <div class="tooltip__content">
                            <span>
                            Direito<br>
                            Administracao<br>
                            Enfermagem<br>
                            Ciencias contabeis<br>
                            Pedagogia<br>
                            Educacao fisica<br>
                            Psicologia<br>
                            Fisioterapia<br>
                            Recursos humanos<br>
                            Nutricao<br>
                            Farmacia<br>
                            Engenharia civil<br>
                            Arquitetura e urbanismo<br>
                            Biomedicina<br>
                            Estetica<br>
                            Analise e desenvolvimento de sistemas<br>
                            Publicidade e propaganda<br>
                            Logistica<br>
                            Engenharia de producao<br>
                            Engenharia mecanica<br>
                            </span>
                          </div>
                        </span>
                      </th>
                    </tr>
                    <tr>
                      <th colspan="2">Total</th>
                      <th>
                      <th colspan="2" v-if="presencialResultset">Presencial</th>
                      <th>
                      <th colspan="2" v-if="eadResultset">EAD</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td>Skus inep total</td>
                      <td>{{ inepShare.inep_skus }}</td>
                      <td></td>
                      <td v-if="presencialResultset">Skus Total</td>
                      <td v-if="presencialResultset">{{ inepShare.inep_skus_presencial }}</td>
                      <td></td>
                      <td v-if="eadResultset">Skus Total</td>
                      <td v-if="eadResultset">{{ inepShare.inep_skus_ead }}</td>
                    </tr>

                    <tr>
                      <td>Skus QB 2018</td>
                      <td>{{ inepShare.qb_skus }}</td>
                      <td></td>
                      <td v-if="presencialResultset">Skus QB 2018</td>
                      <td v-if="presencialResultset">{{ inepShare.presencial_qb }}</td>
                      <td></td>
                      <td v-if="eadResultset">Skus QB 2018</td>
                      <td v-if="eadResultset">{{ inepShare.ead_qb }}</td>
                    </tr>

                    <tr>
                      <td>Skus QB 2018.1</td>
                      <td>{{ inepShare.qb_skus_1 }}</td>
                      <td></td>
                      <td v-if="presencialResultset">Skus QB 2018.1</td>
                      <td v-if="presencialResultset">{{ inepShare.presencial_qb_1 }}</td>
                      <td></td>
                      <td v-if="eadResultset">Skus QB 2018.1</td>
                      <td v-if="eadResultset">{{ inepShare.ead_qb_1 }}</td>
                    </tr>

                    <tr>
                      <td>Skus QB 2018.2</td>
                      <td>{{ inepShare.qb_skus_2 }}</td>
                      <td></td>
                      <td v-if="presencialResultset">Skus QB 2018.2</td>
                      <td v-if="presencialResultset">{{ inepShare.presencial_qb_2 }}</td>
                      <td></td>
                      <td v-if="eadResultset">Skus QB 2018.2</td>
                      <td v-if="eadResultset">{{ inepShare.ead_qb_2 }}</td>
                    </tr>

                    <tr>
                      <td>Skus no Ar</td>
                      <td>{{ inepShare.online_skus }}</td>
                      <td></td>
                      <td v-if="presencialResultset">Skus no Ar</td>
                      <td v-if="presencialResultset">{{ inepShare.presencial_online }}</td>
                      <td></td>
                      <td v-if="eadResultset">Skus no Ar</td>
                      <td v-if="eadResultset">{{ inepShare.ead_online }}</td>
                    </tr>

                    <tr>
                      <td>SKUs QB18 / SKUs INEP 17 ( % da base de alunos)</td>
                      <td>{{ inepShare.qb_skus_enrollment }} %</td>
                      <td></td>
                      <td v-if="presencialResultset">SKUs QB18 / SKUs INEP 17 ( % da base de alunos)</td>
                      <td v-if="presencialResultset">{{ inepShare.qb_skus_enrollment_presencial }} %</td>
                      <td></td>
                      <td v-if="eadResultset">SKUs QB18 / SKUs INEP 17 ( % da base de alunos)</td>
                      <td v-if="eadResultset">{{ inepShare.qb_skus_enrollment_ead }} %</td>
                    </tr>

                    <tr>
                      <td>SKUs QB19.1 Online / SKUs INEP 17 ( % da base de alunos)</td>
                      <td>{{ inepShare.online_skus_enrollment }} %</td>
                      <td></td>
                      <td v-if="presencialResultset">SKUs QB19.1 Online / SKUs INEP 17 ( % da base de alunos)</td>
                      <td v-if="presencialResultset">{{ inepShare.online_skus_enrollment_presencial }} %</td>
                      <td></td>
                      <td v-if="eadResultset">SKUs QB19.1 Online / SKUs INEP 17 ( % da base de alunos)</td>
                      <td v-if="eadResultset">{{ inepShare.online_skus_enrollment_ead }} %</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <div v-show="showMissingTable">

          <div class="panel report-panel panel-default" v-if="stockInepData && (inepPresencialMissing.length > 0 || inepEadMissing.length > 0)">
            <!-- div class="panel-heading panel-heading--spaced-bottom">ESTOQUE FALTANDO DO INEP</div -->
            <div class="row">
              <!-- ul class="nav navbar-nav justify-content-center">
                <li class="navbar__item" :class="{'active' : showPresencialReportTable}" v-if="hasPresencialData">
                  <a class="nav-link clickable" @click="showPresencialInepReport">PRESENCIAL</a>
                </li>
                <li class="navbar__item" :class="{'active' : showEadReportTable}" v-if="hasEadData">
                  <a class="nav-link clickable" @click="showEadInepReport">EAD</a>
                </li>
              </ul -->

              <div class="col-md-12" v-show="presencialResultset">
                <template v-if="inepPresencialMissing.length == 0">
                  <h2>Nenhum curso presencial faltante identificado</h2>
                </template>
                <template v-else>
                  <table id="inep-missing-presencial" class="data-table">
                    <thead>
                      <tr>
                        <th>IES</th>
                        <th>Cidade</th>
                        <th>Estado</th>
                        <th>Curso</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="course in inepPresencialMissing">
                        <td>{{ course.ies_name }}</td>
                        <td>{{ course.city }}</td>
                        <td>{{ course.state }}</td>
                        <td>{{ course.course }}</td>
                      </tr>
                    </tbody>
                  </table>
                </template>
              </div>

              <div class="col-md-12" v-show="eadResultset">
                <template v-if="inepEadMissing.length == 0">
                  Nenhum curso EaD faltante identificado
                </template>
                <template v-else>
                  <table id="inep-missing-ead" class="data-table">
                    <thead>
                      <tr>
                        <th>IES</th>
                        <th>Cidade</th>
                        <th>Estado</th>
                        <th>Curso</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="course in inepEadMissing">
                        <td>{{ course.ies_name }}</td>
                        <td>{{ course.city }}</td>
                        <td>{{ course.state }}</td>
                        <td>{{ course.course }}</td>
                      </tr>
                    </tbody>
                  </table>
                </template>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-12" v-show="showStatesTable">
          <table id="inep-share-states" class="data-table" >
            <thead>
              <tr>
                <th></th>
                <th colspan="6" v-if="presencialResultset">Presencial</th>
                <th colspan="6" v-if="eadResultset">Ead</th>
              </tr>
              <tr>
                <th>Estado</th>
                <template v-if="presencialResultset">
                  <th>Ingressantes Inep [2017]</th>
                  <th>Share QB (%) [ANUAL]</th>
                  <th>SKUs QB18 / SKUs INEP 17 <br>(% da base de alunos)</th>
                  <th>SKUs QB18.1 / SKUs INEP 17 <br>(% da base de alunos)</th>
                  <th>SKUs QB18.2 / SKUs INEP 17 <br>(% da base de alunos)</th>
                  <th>SKUs Online Atual / SKUs INEP 17 <br>(% da base de alunos)</th>
                </template>
                <template v-if="eadResultset">
                  <th>Ingressantes Inep [2017]</th>
                  <th>Share QB (%) [ANUAL]</th>
                  <th>SKUs QB18 / SKUs INEP 17 <br>(% da base de alunos)</th>
                  <th>SKUs QB18.1 / SKUs INEP 17 <br>(% da base de alunos)</th>
                  <th>SKUs QB18.2 / SKUs INEP 17 <br>(% da base de alunos)</th>
                  <th>SKUs Online Atual / SKUs INEP 17 <br>(% da base de alunos)</th>
                </template>
              </tr>
            </thead>
            <tbody>
              <tr v-for="entry in data">
                <td>{{ entry.state }}</td>
                <template v-if="presencialResultset">
                  <td>{{ entry.inep_presencial }}</td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_qb_presencial')">
                    {{ entry.share_qb_presencial }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_presencial')">
                    {{ entry.share_base_alunos_skus_presencial }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_presencial_1')">
                    {{ entry.share_base_alunos_skus_presencial_1 }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_presencial_2')">
                    {{ entry.share_base_alunos_skus_presencial_2 }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_online_presencial')">
                    {{ entry.share_base_alunos_skus_online_presencial }}
                  </td>
                </template>
                <template v-if="eadResultset">
                  <td>{{ entry.inep_ead }}</td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_qb_ead')">
                    {{ entry.share_qb_ead }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_ead')">
                    {{ entry.share_base_alunos_skus_ead }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_ead_1')">
                    {{ entry.share_base_alunos_skus_ead_1 }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_ead_2')">
                    {{ entry.share_base_alunos_skus_ead_2 }}
                  </td>
                  <td :bgcolor="normalizedCellColor(entry, dataStats, 'share_base_alunos_skus_online_ead')">
                    {{ entry.share_base_alunos_skus_online_ead }}
                  </td>
                </template>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="col-md-12" v-show="showIESTable">
          <div class="transparent-loader" v-if="loadingIesData">
            <div class="loader"></div>
          </div>
          <!-- div class="row">
            <div class="col-md-6">
              <label for="level-filter">ESTADO</label>
              <cs-multiselect v-model="locationState" :options="statesSugestions" label="name" placeholder="Todos os estados" selectLabel="" deselectLabel="" selectedLabel="Selecionado" @select="stateSelected" @remove="stateRemoved"></cs-multiselect>
            </div>
          </div -->

          <div class="row">
            <div class="col-md-12" v-if="!loadingIesData">
              <table id="inep-share-ies" class="data-table" >
                <thead>
                  <tr>
                    <th>ID IES</th>
                    <th>IES</th>
                    <th>Farmer</th>
                    <template v-if="presencialResultset">
                      <th>Base de Alunos INEP Presencial [2017]</th>
                      <th>SKUs QB18 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.1 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.2 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB19.1 Online / SKUs INEP 17 <br>(% da base de alunos)</th>
                    </template>
                    <template v-if="eadResultset">
                      <th>Base de Alunos INEP EAD [2017]</th>
                      <th>SKUs QB18 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.1 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.2 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB19.1 Online / SKUs INEP 17 <br>(% da base de alunos)</th>
                    </template>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in iesData">
                    <td>{{ entry.qb_university_id }}</td>
                    <td>{{ entry.ies_name }}</td>
                    <td>{{ entry.owner }}</td>
                    <template v-if="presencialResultset">
                      <td>{{ entry.inep_presencial }}</td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_presencial')">
                        {{ entry.share_base_alunos_skus_presencial }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_presencial_1')">
                        {{ entry.share_base_alunos_skus_presencial_1 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_presencial_2')">
                        {{ entry.share_base_alunos_skus_presencial_2 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_online_presencial')">
                        {{ entry.share_base_alunos_skus_online_presencial }}
                      </td>
                    </template>
                    <template v-if="eadResultset">
                      <td>{{ entry.inep_ead }}</td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_ead')">
                        {{ entry.share_base_alunos_skus_ead }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_ead_1')">
                        {{ entry.share_base_alunos_skus_ead_1 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_ead_2')">
                        {{ entry.share_base_alunos_skus_ead_2 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, iesStats, 'share_base_alunos_skus_online_ead')">
                        {{ entry.share_base_alunos_skus_online_ead }}
                      </td>
                    </template>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="col-md-12" v-show="showLocationTable">
          <div class="transparent-loader" v-if="loadingLocationData">
            <div class="loader"></div>
          </div>

          <div class="row">
            <div class="col-md-12" v-if="!loadingLocationData">
              <!-- se nao tem filtro de estado nao pode mostrar as pracas -->
              <!-- span v-if="!locationState">Selecione um filtro de estado</span -->

              <table id="inep-share-location" class="data-table" >
                <thead>
                  <tr>
                    <th>ID IES</th>
                    <th>IES</th>
                    <th>Cidade</th>
                    <th>Farmer</th>
                    <template v-if="presencialResultset">
                      <th>Base de Alunos INEP Presencial [2017]</th>
                      <th>SKUs QB18 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.1 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.2 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB19.1 Online / SKUs INEP 17 <br>(% da base de alunos)</th>
                    </template>
                    <template v-if="eadResultset">
                      <th>Base de Alunos INEP EAD [2017]</th>
                      <th>SKUs QB18 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.1 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs QB18.2 / SKUs INEP 17 <br>(% da base de alunos)</th>
                      <th>SKUs Online Atual / SKUs INEP 17 <br>(% da base de alunos)</th>
                    </template>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="entry in locationData">
                    <td>{{ entry.qb_university_id }}</td>
                    <td>{{ entry.ies_name }}</td>
                    <td>{{ entry.city }}</td>
                    <td>{{ entry.owner }}</td>
                    <template v-if="presencialResultset">
                      <td>{{ entry.inep_presencial }}</td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_presencial')">
                        {{ entry.share_base_alunos_skus_presencial }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_presencial_1')">
                        {{ entry.share_base_alunos_skus_presencial_1 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_presencial_2')">
                        {{ entry.share_base_alunos_skus_presencial_2 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_online_presencial')">
                        {{ entry.share_base_alunos_skus_online_presencial }}
                      </td>
                    </template>
                    <template v-if="eadResultset">
                      <td>{{ entry.inep_ead }}</td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_ead')">
                        {{ entry.share_base_alunos_skus_ead }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_ead_1')">
                        {{ entry.share_base_alunos_skus_ead_1 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_ead_2')">
                        {{ entry.share_base_alunos_skus_ead_2 }}
                      </td>
                      <td :bgcolor="normalizedCellColor(entry, locationStats, 'share_base_alunos_skus_online_ead')">
                        {{ entry.share_base_alunos_skus_online_ead }}
                      </td>
                    </template>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import MessageDialog from "../js/components/message-dialog";
import DataTable from "../js/components/datatable";
import Multiselect from 'vue-multiselect'
import CsMultiselect from './custom-search-multiselect'
import PanelPrimaryFilter from './panel-primary-filter';
import LocationFilter from './location-filter';

export default {
  data() {
    return {
      loadingIesData: false,
      loadingFilters: true,
      loadingLocationData: false,
      loading: false,
      data: [],
      dataStats: {},
      iesData: [],
      iesStats: {},
      locationData: [],
      locationStats: {},
      accountTypeFilter: null,
      accountTypeOptions: [],
      statesOptions: [],
      statesSugestions: [],
      locationState: null,
      hasLocationData: false,
      hasMissingData: false,
      showStatesTable: true,
      showShareTable: false,
      showIESTable: false,
      showLocationTable: false,
      showMissingTable: false,
      filterOptions: [],
      dealOwnerOptions: [],
      universityOptions: [],
      universityGroupOptions: [],
      currentType: null,
      currentValue: null,
      kindFilter: 1,
      resultsetType: null,
      locationOptions: [
        { name: 'Região', type: 'region'},
        { name: 'Estado', type: 'state'},
        { name: 'Cidade', type: 'city'},
      ],
      citiesOptions: [],
      statesOptions: [],
      regionsOptions: [],
      inepEadMissing: [],
      inepPresencialMissing: [],
      inepShare: [],
      stockInepData: false,
      loadingInepData: false,
    }
  },
  mounted() {
    console.log("mounted");
    InepChannel.on('shareData', (payload) => this.receiveShareData(payload));
    InepChannel.on('iesData', (payload) => this.receiveIesData(payload));
    InepChannel.on('locationData', (payload) => this.receiveLocationData(payload));
    InepChannel.on('filters', (payload) => this.receiveFilters(payload));
    InepChannel.on('citiesComplete', (payload) => this.receiveCitiesComplete(payload));
    InepChannel.on('inepData', (payload) => this.receiveInepReport(payload));

    this.loadFilters();
  },
  components: {
    Multiselect,
    PanelPrimaryFilter,
    CsMultiselect,
    LocationFilter,
  },
  computed: {
    eadResultset() {
      return this.resultsetType == 'ead';
    },
    presencialResultset() {
      return this.resultsetType == 'presencial';
    }
  },
  watch: {
    kindFilter: function(value) {
      this.$nextTick(() => {
        this.primaryFilterSelected();
      });
    }
  },
  methods: {
    locationRemoved() {
      console.log("locationRemoved");
      this.$nextTick(() => {
        this.primaryFilterSelected();
      });
    },
    receiveCitiesComplete(data) {
      this.citiesOptions = data.cities;
    },
    locationSelected() {
      console.log("locationSelected");
      this.primaryFilterSelected();
    },
    loadCities() {
      console.log("loadCities");
      let params = this.filterParams();
      InepChannel.push('citiesComplete', params).receive('timeout', () => {
        console.log("return timeout");
      });
    },
    primaryFilterSelected() {
      let filterData = this.$refs.filter.filterSelected();
      console.log("primaryFilterSelected: " + JSON.stringify(filterData));
      console.log("primaryFilterSelected: TYPE: " + filterData.type + " VALUE: " + JSON.stringify(filterData.value) + " NIL?" + _.isNil(filterData.value));
      if (!_.isNil(filterData.value) && filterData.value != '') {
        this.loadData(filterData.type, filterData.value)
      } else {
        this.data = [];
      }
    },
    /*
    stateRemoved() {
      console.log("stateRemoved LOCATION: " + JSON.stringify(this.locationState));
      this.loadStatesData(null);
      this.loadingLocationData = true;

      this.$nextTick(() => {
        console.log("stateRemoved NEXT TICK LOCATION: " + JSON.stringify(this.locationState));
      });
    },
    stateSelected(data) {
      this.loadStatesData(data.type);
      this.loadLocationData();
    },
    */
    normalizedCellColor(data, stats, key) {
      return this.cellColor(data[key], stats.min[key], stats.max[key], stats.mean[key]);
    },
    cellColor(value, min, max, mean) {
      if (_.isNil(value)) {
        return "#BC2626";
      }
      let decimalValue = eval(value);
      if (decimalValue > mean) {
        let rel = (decimalValue - mean) / (max - mean);
        let colorFac = 40 + Math.round(75 * (1 - rel));
        let factorString = colorFac.toString(16).padStart(2, '0');
        let colorValue = `#${factorString}68${factorString}`;
        return colorValue;
      }
      let rel = (mean - decimalValue) / (mean - min);
      let colorFac = 26 + Math.round(162 * (1 - rel));
      let factorString = colorFac.toString(16).padStart(2, '0');
      let colorValue = `#BC${factorString}${factorString}`;
      return colorValue;
    },
    showShare() {
      this.showShareTable = true;
      this.showIESTable = false;
      this.showStatesTable = false;
      this.showLocationTable = false;
      this.showMissingTable = false;
    },
    showStates() {
      this.showIESTable = false;
      this.showStatesTable = true;
      this.showLocationTable = false;
      this.showShareTable = false;
      this.showMissingTable = false;
    },
    showIES() {
      this.showStatesTable = false;
      this.showIESTable = true;
      this.showLocationTable = false;
      this.showShareTable = false;
      this.showMissingTable = false;
    },
    showLocation() {
      this.showStatesTable = false;
      this.showIESTable = false;
      this.showLocationTable = true;
      this.showShareTable = false;
      this.showMissingTable = false;
    },
    showMissing() {
      this.showStatesTable = false;
      this.showIESTable = false;
      this.showLocationTable = false;
      this.showShareTable = false;
      this.showMissingTable = true;
    },
    loadLocationData() {
      this.loadingLocationData = true;
      let params = this.filterParams();
      InepChannel.push('filterStateLocations', params).receive('timeout', () => {
        console.log("return timeout");
      });
    },
    /*
    //vai fazer sentido ter esse?
      //o filtro vai ficar la em cima, sempre que aplicar estado tem que ter esse filtro!
      //quando vamos mostrar dados de localidade?
    loadStatesData(state) {
      console.log("DEPRECADO loadStatesData");
      this.loadingIesData = true;
      let params = {
        type: this.currentType,
        value: this.currentValue,
        state: state,
        kind_id: this.kindFilter
      };
      InepChannel.push('filterState', params).receive('timeout', () => {
        console.log("return timeout");
      });
    },
    */
    filterParams() {
      let params = { type: this.currentType, value: this.currentValue, kind_id: this.kindFilter }
      if (this.$refs.locationFilter.locationValue()) {
        params.locationType = this.$refs.locationFilter.locationFilter();
        params.locationValue = this.$refs.locationFilter.locationValue();
      }
      return params;
    },
    loadData(type, value) {
      this.currentType = type;
      this.currentValue = value;
      this.loading = true;
      this.loadingIesData = true;
      this.locationState = null;
      this.hasLocationData = false;
      this.hasMissingData = false;
      this.data = [];

      let params = this.filterParams();
      InepChannel.push('load', params).receive('timeout', () => {
        console.log("return timeout");
      });

      if (params.locationType == 'state' || params.locationType == 'city') {
        this.loadLocationData();
      }
    },
    loadFilters() {
      InepChannel.push('loadFilters').receive('timeout', () => {
        console.log("return timeout");
      });
    },
    receiveInepReport(data) {
      this.stockInepData = true;
      this.loadingInepData = false;

      this.inepPresencialMissing = data.presencial;
      this.inepEadMissing = data.ead;
      this.inepShare = data.share;

      if (this.inepEadMissing.length > 0) {
        this.hasMissingData = true;
        this.$nextTick(() => {
          this.table = new DataTable('#inep-missing-ead', {
            paging: true,
            deferRender: true,
            searchDelay: 500,
            pageLength: 10,
            order: [ 1, 'desc' ]
          });
        });
      }

      if (this.inepPresencialMissing.length > 0) {
        this.hasMissingData = true;
        this.$nextTick(() => {
          this.table = new DataTable('#inep-missing-presencial', {
            paging: true,
            deferRender: true,
            searchDelay: 500,
            pageLength: 10,
            order: [ 1, 'desc' ]
          });
        });
      }
    },
    receiveLocationData(data) {
      console.log("receiveLocationData");
      this.locationData = data.location_data;
      this.locationStats = data.location_data_stats;
      this.loadingLocationData = false;
      this.hasLocationData = true;

      this.$nextTick(() => {
        this.table = new DataTable('#inep-share-location', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 4, 'desc' ]
        });
      });
    },
    receiveFilters(data) {
      this.accountTypeOptions = data.accountTypes;
      this.loadingFilters = false;
      this.statesOptions = data.states;
      this.statesSugestions = data.states;

      this.filterOptions = data.filters;
      this.dealOwnerOptions = data.dealOwners;
      this.universityOptions = data.universities;
      this.universityGroupOptions = data.universityGroups
      this.statesOptions = data.states;
      this.regionsOptions = data.regions;

      this.$refs.filter.setFilterType({type: "account_type", name: "Carteira"})
    },
    receiveIesData(data) {
      console.log("receiveIesData");
      this.iesData = data.ies_data;
      this.iesStats = data.ies_data_stats;
      this.loadingIesData = false;

      if (this.currentType === 'university' || this.currentType === 'group') {
        this.showShare();
      } else {
        this.showStates();
      }

      this.$nextTick(() => {
        console.log("receiveIesData NEXT TICK");
        this.table = new DataTable('#inep-share-ies', {
          paging: true,
          deferRender: true,
          searchDelay: 500,
          pageLength: 10,
          order: [ 3, 'desc' ]
        });
        console.log("receiveIesData TABLE FINISHED LL: " + this.loadingIesData);
      });
    },
    receiveShareData(data) {
      this.data = data.table_data;
      this.dataStats = data.table_data_stats;
      this.loading = false;
      this.resultsetType = data.resultset_type;
      console.log("received resultsetType: " + this.resultsetType);

      if (this.data != []) {
        this.$nextTick(() => {
          this.table = new DataTable('#inep-share-states', {
            paging: true,
            deferRender: true,
            searchDelay: 500,
            pageLength: 10,
            order: [ 1, 'desc' ]
          });
        });
      }
    }
  }
}
</script>
