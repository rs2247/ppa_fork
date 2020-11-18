<template>
  <div class="container-fluid">
    <div class="row">
      <div class="col-12">
        <h2 class="content-header">
          Dashboard
        </h2>
      </div>
    </div>


    <modal-dialog ref="exportModal" :identification="exporting-modal">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal">&times;</button>
        <h2 class="modal-title">SELECIONE A SÉRIE PARA EXPORTAR</h2>
      </div>
      <div class="modal-body">
        <div class="row">
          <div class="col-md-6 col-sm-12">
            <multiselect v-model="exportSelection" :options="chartsKeysNames" placeholder="Selecione a série"></multiselect>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-submit" @click="exportBySelection">Exportar</button>
      </div>
    </modal-dialog>

    <div class="row" style="position: relative;">
      <div class="transparent-loader" v-if="filtersLoading || loading">
        <div class="loader"></div>
      </div>

      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-body no-lat-padding">
            <panel-filter :period-disabled="false" ref="currentFilter" index="0" @primaryFilterSelected="currentPrimarySelected" @locationTypeSelected="currentLocationTypeSelected" @locationSelected="currentLocationSelected" @timeRangeSelected="currentRangeSelected" @kindSelected="currentKindSelected" @levelSelected="currentLevelSelected" @productLineSelected="currentProductLineSelected" @productLineSelectionTypeSelected="currentProductLineSelectionTypeSelected" @locationRemoved="currentLocationRemoved"></panel-filter>

            <div class="row">
              <div class="col-md-12 col-sm-12">
                <div class="row">
                  <div class="col-md-3 col-sm-12">
                    <div>
                      <label>COMPARATIVO</label>
                      <multiselect v-model="comparingMode" :options="comparingOptions" :allowEmpty="false" label="name" track-by="type" placeholder="Selecione o comparativo" selectLabel="Enter para selecionar" deselectLabel=""></multiselect>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <panel-filter :period-disabled="true" :filter-disabled="comparingDisabled" ref="comparingFilter" index="1" v-show="showComparingFilter" @locationTypeSelected="currentLocationTypeSelected"></panel-filter>


            <div class="row" v-show="showGroupingOptions">
              <div class="col-md-3 col-sm-12">
                <label>AGRUPAR POR</label>
                <multiselect v-model="grouping" :options="currentGroupingOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input="groupValueSelected"></multiselect>
              </div>

              <div class="col-md-3 col-sm-12" v-show="grouping">
                <label>NÚMERO DE SÉRIES</label>
                <multiselect v-model="groupingMax" :options="groupingMaxOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input="groupMaxSelected"></multiselect>
              </div>

              <template v-if="canSelectSeries">

                <div class="col-md-3 col-sm-12" v-show="grouping">
                  <label>SELEÇÃO DE SÉRIES</label>
                  <multiselect v-model="seriesSelection" :options="seriesSelectionOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input=""></multiselect>
                </div>


                <div class="col-md-3 col-sm-12" v-show="grouping">
                  <label>CAMPO DE SELEÇÃO</label>
                  <multiselect v-model="seriesSelectionField" :allow-empty="false" :options="seriesSelectionFieldOptions" label="name" track-by="id" placeholder="Selecione o agrupamento" selectLabel="" deselectLabel="" @input=""></multiselect>
                </div>
              </template>
            </div>

            <div class="row">
              <div class="col-md-6 col-sm-12">
                <div class="default-margin-top flex-vertical-centered">
                  <button class="btn-submit" @click="update" :enabled="updateEnabled">
                    Atualizar
                  </button>

                  <div style="justify-content: flex-end; margin-left: 50px;">
                    <div :class="consolidatedButtonClass" style="display: inline; padding: 3px;">
                      <span class=" glyphicon glyphicon-barcode" @click="consolidatedCharts" title="Gráficos lado a lado"></span>
                    </div>
                    <div :class="expandedButtonClass" style="display: inline; padding: 3px;">
                      <span class="glyphicon glyphicon-book" @click="expandedCharts" title="Gráficos em linhas"></span>
                    </div>
                  </div>


                  <div style="justify-content: flex-end; margin-left: 50px;">
                    <div :class="linesButtonClass" style="display: inline; padding: 3px;">
                      <span class=" glyphicon glyphicon-flash" @click="setLineCharts" title="Gráfico de linhas"></span>
                    </div>
                    <div :class="barsButtonClass" style="display: inline; padding: 3px;">
                      <span class=" glyphicon glyphicon-stats" @click="setBarCharts" title="Gráfico de barras"></span>
                    </div>

                  </div>


                  <div class="small-margin-left">

                    <div  class="dropdown" data-ref="export-data" style="border: none !important;">
                      <div class="dropdown-toggle" data-toggle="dropdown">
                        <span class="flex-grow dropdown-label" style="margin-right: 5px;">Opções</span>
                        <span class="glyphicon glyphicon-chevron-down float-right"></span>
                      </div>
                      <ul class="dropdown-menu">
                        <li><a v-show="lineCharts" class="clickable" @click="toggleMovelMean()"> <span class="glyphicon glyphicon-check float-right" v-if="movelMean"></span> Média móvel</a></li>
                        <li><a v-show="!lineCharts" class="clickable" @click="toggleBarsValues()"> <span class="glyphicon glyphicon-check float-right" v-if="barsValues"></span> Valores nas barras</a></li>

                        <li>
                          <a class="clickable" @click="exportData()">
                            <span class="glyphicon glyphicon-download-alt"></span>
                            Exportar
                          </a>
                        </li>
                        <li>
                          <a class="clickable" @click="toggleBeginAtZero()">
                            <span class="glyphicon glyphicon-check" v-if="beginChartsAtZero"></span>
                            Iniciar gráficos no zero
                          </a>
                        </li>
                      </ul>
                    </div>
                  </div>

                  <div class="small-margin-left">

                    <div  class="dropdown" data-ref="export-data" style="border: none !important;">
                      <div class="dropdown-toggle" data-toggle="dropdown">
                        <span class="flex-grow dropdown-label" style="margin-right: 5px;">Exibição</span>
                        <span class="glyphicon glyphicon-chevron-down float-right"></span>
                      </div>
                      <ul class="dropdown-menu">
                        <li>
                          <a class="clickable" @click="setCustomizedView('all_charts')">
                            <span class="glyphicon glyphicon-check float-right" v-if="exibitionType == 'all_charts'"></span>
                            Todos os gráficos
                          </a>
                        </li>
                        <li>
                          <a class="clickable" @click="setCustomizedView('partner_charts')">
                            <span class="glyphicon glyphicon-check float-right" v-if="exibitionType == 'partner_charts'"></span>
                            Parceiro
                          </a>
                        </li>
                        <li>
                          <a class="clickable" @click="setCustomizedView('rates_charts')">
                            <span class="glyphicon glyphicon-check float-right" v-if="exibitionType == 'rates_charts'"></span>
                            Taxas
                          </a>
                        </li>
                        <li>
                          <a class="clickable" @click="setCustomizedView('stock_charts')">
                            <span class="glyphicon glyphicon-check float-right" v-if="exibitionType == 'stock_charts'"></span>
                            Estoque
                          </a>
                        </li>
                        <li class="dropdown-submenu">
                          <a class="clickable">
                            <span class="glyphicon glyphicon-check float-right" v-if="exibitionType == 'custom_charts'"></span>
                            Escolher graficos
                          </a>
                          <ul class="dropdown-menu">
                            <li v-for="entry in chartsMap">
                              <a class="clickable" @click="toggleChart(entry.name)">
                                <span class="glyphicon glyphicon-check float-right" v-if="chartClass(entry.name) != 'hidden'"></span>
                                {{ entry.display_name }}
                              </a>
                            </li>
                          </ul>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">


      <div class="col-md-12 col-sm-12">
        <div class="panel report-panel panel-default">

          <div class="panel-heading panel-heading--spaced-bottom">
            CONSOLIDADO
            <div style="float: right">
              <span v-if="tableExpanded" class="glyphicon glyphicon-menu-up clickable" @click="collapseTable()" title="Colapsar"></span>
              <span v-if="!tableExpanded" class="glyphicon glyphicon-menu-down clickable" @click="expandTable()" title="Expandir"></span>
            </div>
          </div>

          <div class="row" v-show="tableExpanded">
            <div class="col-md-12 col-sm-12">
              <div class="transparent-loader" v-if="tableLoading">
                <div class="loader"></div>
              </div>

              <div class="row">
                <div class="col-md-12 col-sm-12">
                  <table class="data-table data-table-tiny">
                    <thead>
                      <tr v-if="metrics[0] && metricsNames">
                        <th></th>
                        <th :colspan="metrics[0].length">{{ seriesNames[0] }}</th>
                        <template v-if="metrics[1]">
                          <th style="width: 70px; background-color: #3B4347;"></th>
                          <th :colspan="metrics[1].length">{{ seriesNames[1] }}</th>
                        </template>
                        <template v-if="metricsCompare">
                          <th style="width: 70px; background-color: #3B4347;"></th>
                          <th :colspan="metricsCompare.length">Variação</th>
                        </template>
                      </tr>
                      <tr>
                        <th></th>
                        <th v-for="serie in metrics[0]">
                          {{ serie.series_name }}
                        </th>
                        <template v-if="metrics[1]">
                          <th style="width: 70px; background-color: #3B4347;"></th>
                          <th v-for="serie in metrics[1]">
                            {{ serie.series_name }}
                          </th>
                        </template>
                        <template v-if="metricsCompare">
                          <th style="width: 70px; background-color: #3B4347;"></th>
                          <th v-for="serie, index in metricsCompare">
                            <span v-for="n in index + 1">I</span>
                          </th>
                        </template>
                      </tr>
                    </thead>
                    <tbody>
                      <!-- uma linha para cada metrica -->
                      <tr v-for="metricEntry in metricsNames" >
                        <td>{{ metricEntry.name }}</td>
                        <td v-for="serie in metrics[0]">
                          {{ serie.table[metricEntry.key] }}
                        </td>
                        <template v-if="metrics[1]">
                          <td></td>
                          <td v-for="serie in metrics[1]">
                            {{ serie.table[metricEntry.key] }}
                          </td>
                        </template>

                        <template v-if="metricsCompare">
                          <td></td>
                          <td v-for="serie in metricsCompare" class="no-wrap">
                            <span class="glyphicon glyphicon-arrow-up compare-arrow-up" v-if="positiveMetric(serie[metricEntry.key])"></span>
                            <span class="glyphicon glyphicon-arrow-down compare-arrow-down" v-if="negativeMetric(serie[metricEntry.key])"></span>
                            {{ serie[metricEntry.key] }} <span v-if="serie[metricEntry.key] != '-'">%</span>
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
    </div>

    <div class="row">

      <div :class="chartClass('atractionChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Taxa de Atratividade (%)
            <div style="float: right">
              <span v-if="canCollapseChart('atractionChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('atractionChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('atractionChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('atractionChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('atractionChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="atractionChart" export-name="taxa_atratividade"></base-chart>
        </div>
      </div>

      <div :class="chartClass('successChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Taxa de Sucesso (%)
            <div style="float: right">
              <span v-if="canCollapseChart('successChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('successChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('successChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('successChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('successChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="successChart" export-name="taxa_sucesso"></base-chart>
        </div>
      </div>

      <div :class="chartClass('conversionChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Taxa de Conversão (%)
            <div style="float: right">
              <span v-if="canCollapseChart('conversionChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('conversionChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('conversionChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('conversionChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('conversionChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="conversionChart" export-name="taxa_conversao"></base-chart>
        </div>
      </div>

      <div :class="chartClass('ordersChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Ordens Iniciadas
            <div style="float: right">
              <span v-if="canCollapseChart('ordersChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('ordersChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('ordersChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('ordersChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('ordersChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="ordersChart" export-name="ordens_iniciadas"></base-chart>
        </div>
      </div>


      <div :class="chartClass('paidsChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Ordens Pagas
            <div style="float: right">
              <span v-if="canCollapseChart('paidsChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('paidsChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('paidsChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('paidsChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('paidsChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="paidsChart" export-name="ordens_pagas"></base-chart>
        </div>
      </div>


      <div :class="chartClass('visitsChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Visitas em páginas de ofertas
            <div style="float: right">
              <span v-if="canCollapseChart('visitsChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('visitsChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('visitsChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('visitsChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('visitsChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="visitsChart" export-name="visitas_ofertas"></base-chart>
        </div>
      </div>

      <div :class="chartClass('universityVisitsChart')" v-show="hasChart('universityVisitsChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Visitas em páginas de universidade
            <div style="float: right">
              <span v-if="canCollapseChart('universityVisitsChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('universityVisitsChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('universityVisitsChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('universityVisitsChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('universityVisitsChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="universityVisitsChart" export-name="visitas_universidade"></base-chart>
        </div>
      </div>

      <div :class="chartClass('revenueChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Receita ( com LTV )
            <div style="float: right">
              <span v-if="canCollapseChart('revenueChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('revenueChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('revenueChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('revenueChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('revenueChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="revenueChart" export-name="receita"></base-chart>
        </div>
      </div>

      <div :class="chartClass('velocimeterChart')" v-show="hasChart('velocimeterChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Velocimetro
            <div style="float: right">
              <span v-if="canCollapseChart('velocimeterChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('velocimeterChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('velocimeterChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('velocimeterChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('velocimeterChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="velocimeterChart" export-name="velocimetro"></base-chart>
        </div>
      </div>

      <!-- div :class="chartClass('qapRevenueChart')" v-show="hasChart('qapRevenueChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Receita LTV
            <div style="float: right">
              <span v-if="canCollapseChart('qapRevenueChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('qapRevenueChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('qapRevenueChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('qapRevenueChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('qapRevenueChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="qapRevenueChart" export-name="receita_qap"></base-chart>
        </div>
      </div -->

      <div :class="chartClass('meanTicketChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Ticket Médio ( LTV )
            <div style="float: right">
              <span v-if="canCollapseChart('meanTicketChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('meanTicketChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('meanTicketChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('meanTicketChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('meanTicketChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="meanTicketChart" export-name="ticket_medio_ltv"></base-chart>
        </div>
      </div>

      <div :class="chartClass('legacyMeanTicketChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Ticket Médio ( Pré-Matrícula )
            <div style="float: right">
              <span v-if="canCollapseChart('legacyMeanTicketChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('legacyMeanTicketChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('legacyMeanTicketChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('legacyMeanTicketChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('legacyMeanTicketChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="legacyMeanTicketChart" export-name="ticket_medio_pef"></base-chart>
        </div>
      </div>

      <div :class="chartClass('meanIncomeChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Faturamento por ordem ( LTV )
            <div style="float: right">
              <span v-if="canCollapseChart('meanIncomeChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('meanIncomeChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('meanIncomeChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('meanIncomeChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('meanIncomeChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="meanIncomeChart" export-name="faturamento_por_ordem_ltv"></base-chart>
        </div>
      </div>

      <div :class="chartClass('legacyMeanIncomeChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Faturamento por ordem ( Pré-Matricula )
            <div style="float: right">
              <span v-if="canCollapseChart('legacyMeanIncomeChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('meanIncomeChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('meanIncomeChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('legacyMeanIncomeChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('meanIncomeChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="legacyMeanIncomeChart" export-name="faturamento_por_ordem_pef"></base-chart>
        </div>
      </div>

      <div :class="chartClass('refundsChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            REEMBOLSOS
            <div style="float: right">
              <span v-if="canCollapseChart('refundsChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('refundsChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('refundsChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('refundsChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('refundsChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="refundsChart" export-name="reembolsos"></base-chart>
        </div>
      </div>

      <div :class="chartClass('cumRefundsChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            REEMBOLSOS / PAGOS ( acumulado no período )
            <div style="float: right">
              <span v-if="canCollapseChart('cumRefundsChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('cumRefundsChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('cumRefundsChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('cumRefundsChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('cumRefundsChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="cumRefundsChart" export-name="reembolsos_acumulados_por_pagos"></base-chart>
        </div>
      </div>

      <div :class="chartClass('bosChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            BOS
            <div style="float: right">
              <span v-if="canCollapseChart('bosChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('bosChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('bosChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('bosChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('bosChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="bosChart" export-name="bos"></base-chart>
        </div>
      </div>

      <div :class="chartClass('cumBosChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            BOS / PAGOS ( acumulado no período )
            <div style="float: right">
              <span v-if="canCollapseChart('cumBosChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('cumBosChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('cumBosChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('cumBosChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('cumBosChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="cumBosChart" export-name="bos_acumulados_por_pagos"></base-chart>
        </div>
      </div>

      <div :class="chartClass('stockChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Estoque - SKU's
            <div style="float: right">
              <span v-if="canCollapseChart('stockChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('stockChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('stockChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('stockChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('stockChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="stockChart" export-name="estoque"></base-chart>
        </div>
      </div>

      <div :class="chartClass('discountChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Estoque - Média do desconto oferecido
            <div style="float: right">
              <span v-if="canCollapseChart('discountChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('discountChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('discountChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('discountChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('discountChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="discountChart" export-name="desconto"></base-chart>
        </div>
      </div>

      <div :class="chartClass('offeredChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Estoque - Média do preço oferecido
            <div style="float: right">
              <span v-if="canCollapseChart('offeredChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('offeredChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('offeredChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('offeredChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('offeredChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="offeredChart" export-name="preco_oferecido"></base-chart>
        </div>
      </div>

      <div :class="chartClass('deepStockChart')" v-show="hasChart('deepStockChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Estoque profundo - SKU's
            <div style="float: right">
              <span v-if="canCollapseChart('deepStockChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('deepStockChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('deepStockChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('deepStockChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('deepStockChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="deepStockChart" export-name="estoque_profundo"></base-chart>
        </div>
      </div>

      <div :class="chartClass('exchangesChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Trocas realizadas
            <div style="float: right">
              <span v-if="canCollapseChart('exchangesChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('exchangesChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('exchangesChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('exchangesChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('exchangesChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="exchangesChart" export-name="trocas_realizadas"></base-chart>
        </div>
      </div>

      <div :class="chartClass('cumPaidsChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Acumulado de pagos
            <div style="float: right">
              <span v-if="canCollapseChart('cumPaidsChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('cumPaidsChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('cumPaidsChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('cumPaidsChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('cumPaidsChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="cumPaidsChart" export-name="acumulado_de_pagos"></base-chart>
        </div>
      </div>

      <div :class="chartClass('cumRevenueChart')">
        <div class="panel report-panel panel-default">
          <div class="panel-heading panel-heading--spaced-bottom">
            Acumulado de receita
            <div style="float: right">
              <span v-if="canCollapseChart('cumRevenueChart')" style="" class="glyphicon glyphicon-menu-left clickable" @click="collapseChart('cumRevenueChart')" title="Colapsar"></span>
              <span style="" class="glyphicon glyphicon-remove-sign clickable" @click="closeChart('cumRevenueChart')" title="Fechar gráfico"></span>
              <span v-if="canExpandChart('cumRevenueChart')" style="" class="glyphicon glyphicon-menu-right clickable" @click="expandChart('cumRevenueChart')" title="Expandir"></span>
            </div>
          </div>
          <base-chart ref="cumRevenueChart" export-name="acumulado_de_receita"></base-chart>
        </div>
      </div>

    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import Multiselect from 'vue-multiselect'
import moment from 'moment';
import PanelFilter from './panel-filter';
import BaseChart from './base-chart';
import ComparingChart from './comparing-chart';
import Export from '../js/utils/export';
import ModalDialog from './modal-dialog'

export default {
  data() {
    return {
      colConfig: 6,
      loading: false,
      filtersLoading: true,
      updateEnabled: true,
      comparingMode: '',
      comparingDisabled: false,
      movelMean: true,
      lineCharts: true,
      barsValues: true,
      comparingOptions: [
        { name: 'Ano a Ano', type: 'year_to_year' },
        { name: 'Site Todo', type: 'all_data' },
        { name: 'Customizado', type: 'custom_compare' },
        { name: 'Período Anterior', type: 'previous_period' },
        { name: 'Agrupamento', type: 'grouping' },
        { name: 'Sem comparativo', type: 'no_compare' },
      ],
      groupingMaxOptions: [
        { name: 'Top 5', id: 5 },
        { name: 'Top 10', id: 10 },
        { name: 'Top 15', id: 15 },
        { name: 'Top 20', id: 20 },
        { name: 'Máximo', id: 0 },
      ],
      groupingOptions: [
        { name: "Estado", id: "state" },
        { name: "Carteira", id: "account_type" },
        { name: "IES", id: "university" },
        { name: "Grupo Educacional", id: "group" },
        { name: "Nível", id: "level" },
        { name: "Modalidade", id: "kind" },
        { name: "Cidade", id: "city" },
      ],
      seriesSelectionOptions: [
        { name: 'Maiores altas (na última semana)' , id: 'higher_up' },
        { name: 'Maiores baixas (na última semana)' , id: 'higher_down' },
        { name: 'Maiores altas (no último mês)' , id: 'higher_up_month' },
        { name: 'Maiores baixas (no último mês)' , id: 'higher_down_month' },
        { name: 'Maiores somas no período' , id: 'higher' },
        // { name: 'Menores somas no período' , id: 'lower' },
        { name: 'Maiores valores no final' , id: 'higher_final' },
        // { name: 'Menores valores no final' , id: 'lower_final' },
      ],
      seriesSelectionFieldOptions: [
        { name: 'Ordens', id: 'orders' },
        { name: 'Visitas', id: 'visits' },
        { name: 'Pagos', id: 'paids' },
        { name: 'Receita', id: 'income' },
      ],
      currentGroupingOptions: [],
      grouping: null,
      groupingMax: null,
      seriesSelection: null,
      seriesSelectionField: null,
      chartsMap: {},
      chartsClassesMap: {},
      barCharts: [],
      chartsDates: [],
      chartsKeys: [],
      chartsKeysNames: [],

      seriesNames: [],
      metricsNames: [],
      metrics: [],
      metricsCompare: null,
      tableExpanded: false,
      userTableExpanded: null,
      baseMetrics: [],
      exportSelection: null,
      allCharts: [
        'atractionChart',
        'successChart',
        'conversionChart',
        'ordersChart',
        'paidsChart',
        'visitsChart',
        'universityVisitsChart',
        'revenueChart',
        'velocimeterChart',
        // 'qapRevenueChart',
        'meanTicketChart',
        'legacyMeanTicketChart',
        'meanIncomeChart',
        'legacyMeanIncomeChart',
        'refundsChart',
        'bosChart',
        'stockChart',
        'discountChart',
        'offeredChart',
        'exchangesChart',
        'cumBosChart',
        'cumRefundsChart',
        'deepStockChart',
        'cumPaidsChart',
        'cumRevenueChart'
      ],

      exibitionType: 'all_charts',
      customizedViewsCharts: {
        'partner_charts': ['atractionChart','successChart','conversionChart','ordersChart','paidsChart','visitsChart','deepStockChart', 'stockChart', 'discountChart', 'offeredChart'],
        'rates_charts': ['atractionChart','successChart','conversionChart','ordersChart','paidsChart','visitsChart'],
        'stock_charts': ['deepStockChart', 'stockChart', 'discountChart', 'offeredChart']
      },

      beginChartsAtZero: false,
    }
  },
  components: {
    Multiselect,
    PanelFilter,
    BaseChart,
    ComparingChart,
    ModalDialog,
  },
  watch: {
    comparingMode: function(value) {
      //so seta o periodo? e os filtros?
      console.log("comparingMode: " + JSON.stringify(value));
      if (value.type == 'previous_period') {
        this.comparingDisabled = true;
        this.syncComparingFilters();
        this.setPreviousPeriod();
      } else {
        if (value.type == 'year_to_year') {
          this.setPreviousYearPeriod();
          this.syncComparingFilters();
        } else {
          if (value.type == 'all_data') {
            this.syncBaseComparingFilters();
            this.$refs.comparingFilter.clearPrimaryFilters();
          }
          this.setCurrentPeriod();
        }
        this.comparingDisabled = false;
      }
    }
  },
  mounted() {
    DashboardChannel.on('filterData', (payload) => this.receiveFilterData(payload));
    DashboardChannel.on('chartData', (payload) => this.receiveChartData(payload));
    DashboardChannel.on('citiesFilterData', (payload) => this.receiveCitiesFilterData(payload));
    DashboardChannel.on('campusFilterData', (payload) => this.receiveCampusFilterData(payload));
    DashboardChannel.on('tableData', (payload) => this.receiveTableData(payload));
    DashboardChannel.on('tableMetrics', (payload) => this.receiveTableMetrics(payload));

    this.comparingMode = this.comparingOptions[0];

    this.currentGroupingOptions = this.groupingOptions;
    this.groupingMax = this.groupingMaxOptions[0];
    this.seriesSelection = this.seriesSelectionOptions[0];
    this.seriesSelectionField = this.seriesSelectionFieldOptions[0];

    this.hideAllCharts();
    this.loadFilters();
  },
  computed: {
    ordersChartClass() {
      return "col-md-6";
    },
    ordersChart1Class() {
      return "col-md-6";
    },
    consolidatedButtonClass() {
      if (this.colConfig == 12) {
        return "clickable";
      }
      return "active-border clickable";
    },
    expandedButtonClass() {
      if (this.colConfig == 6) {
        return "clickable";
      }
      return "active-border clickable";
    },
    barsButtonClass() {
      if (this.lineCharts) {
        return "clickable";
      }
      return "active-border clickable";
    },
    linesButtonClass() {
      if (this.lineCharts) {
        return "active-border clickable";
      }
      return "clickable";
    },
    showComparingFilter() {
      if (this.comparingMode == '')
        return false;
      return this.comparingMode.type == 'custom_compare'; // || this.comparingMode.type == 'previous_period';
    },
    showGroupingOptions() {
      if (this.comparingMode == '')
        return false;
      return this.comparingMode.type == 'grouping';
    },
    canSelectSeries() {
      if (_.isNil(this.grouping)) return true;
      if (_.isNil(this.$refs.currentFilter)) return true;

      if (!_.isNil(this.$refs.currentFilter.baseFiltersList()[0]) && this.$refs.currentFilter.baseFiltersList()[0].type != 'universities') {
        return true;
      }
      return _.isNil(this.grouping) || this.grouping['id'] != 'university';
    },
  },
  methods: {
    toggleBeginAtZero() {
      this.loading = true;
      this.beginChartsAtZero = !this.beginChartsAtZero;
      setTimeout(() => {
        for (var chartName in this.chartsMap) {
          if (this.beginChartsAtZero) {
            this.$refs[chartName].setYBeginAtZero(true);
          } else {
            this.$refs[chartName].setYBeginAtZero(false);
          }
          this.$refs[chartName].updateChart();
        }
        this.loading = false;
      }, 50);
    },
    chartVisibleForView(chartName) {
      if (this.exibitionType == 'all_charts') {
        return true;
      }
      if (this.exibitionType in this.customizedViewsCharts) {
        return _.includes(this.customizedViewsCharts[this.exibitionType], chartName);
      }
      console.log("chartVisibleForView customizado chartName: " + chartName + " class: " + this.chartClass(chartName));
      if (this.chartClass(chartName) == 'hidden') {
        return false;
      }
      return true;
    },
    toggleChart(chartName) {
      if (chartName in this.chartsMap) {
        this.exibitionType = 'custom_charts'
        if (this.chartClass(chartName) == 'hidden') {
          this.showChart(chartName);
          this.renderChart(chartName);
          this.$nextTick(() => {
            this.$refs[chartName].updateChart();
          });
        } else {
          this.closeChart(chartName);
        }
      }
    },
    setCustomizedView(type) {
      if (type == 'all_charts') {
        for (var chartName in this.chartsMap) {
          this.showChart(chartName);
          this.renderChart(chartName);
        }
        this.$nextTick(() => {
          for (var chartName in this.chartsMap) {
            this.$refs[chartName].updateChart();
          }
        });
      } else {
        if (type in this.customizedViewsCharts) {
          this.closeExcept(this.customizedViewsCharts[type]);
        } else {
          return;
        }
      }
      this.exibitionType = type;
    },
    closeExcept(exceptList) {
      for (var chartName in this.chartsMap) {
        // console.log("chartName: " + chartName);
        if (!_.includes(exceptList, chartName)) {
          this.closeChart(chartName);
        } else {
          this.showChart(chartName);
          this.renderChart(chartName);
        }
      }
      this.$nextTick(() => {
        _.forEach(exceptList, (chartName) => {
          this.$refs[chartName].updateChart();
        });
      });
    },
    exportData() {
      if (this.chartsKeys.length == 1) {
        this.executeExportData(0);
      } else {
        this.$refs.exportModal.show();
      }
    },
    exportBySelection() {
      if (_.isNil(this.exportSelection)) {
        alert('Selecione uma série para exportar');
        return;
      }
      this.$refs.exportModal.setLoader();
      this.executeExportData(this.chartsKeysNames.indexOf(this.exportSelection));
      this.$refs.exportModal.resetLoader();
      this.$refs.exportModal.close();
    },
    executeExportData(index) {
      let key = this.chartsKeys[index];
      let exportList = [ this.chartsDates ];
      let fields = [ 'Data' ];

      _.forEach(Object.keys(this.chartsMap), (chartName) => {
        if (chartName in this.$refs) {
          let chartData = this.chartsMap[chartName];
          //precisa da serie de datas!
          console.log("NAME: " + chartData.display_name);
          fields.push(chartData.display_name);

          let baseSerie = [];
          if (this.lineCharts) {
            if (this.movelMean) {
              if (chartData.options.no_mean) {
                baseSerie = this.chartsMap[chartName].raw[key];
              } else {
                baseSerie = this.chartsMap[chartName].mean[key];
              }
            } else {
              baseSerie = this.chartsMap[chartName].raw[key];
            }
          } else {
            if (chartData.options.no_bar) {
              if (chartData.options.no_bar_with_mean) {
                baseSerie = this.chartsMap[chartName].mean[key];
              } else {
                baseSerie = this.chartsMap[chartName].raw[key];
              }
            } else {
              baseSerie = this.chartsMap[chartName].bar[key];
            }
          }

          exportList.push(baseSerie);
        }
      });

      Export.exportData('dashboard_' + this.chartsKeysNames[index], exportList, fields);
    },
    positiveMetric(value) {
      return value > 0;
    },
    negativeMetric(value) {
      return value < 0;
    },
    //interface manipulators
    syncComparingFilters() {
      this.syncBaseComparingFilters();
      this.$refs.comparingFilter.setPrimaryFilters(this.$refs.currentFilter.baseFiltersList());
      this.$refs.comparingFilter.setDateRange([moment(this.$refs.currentFilter.dateRange[0]).subtract(12, 'months').toDate(),moment(this.$refs.currentFilter.dateRange[1]).subtract(12, 'months').toDate()]);
    },
    syncBaseComparingFilters() {
      this.$refs.comparingFilter.setProductLineFilter(this.$refs.currentFilter.filterProductLine);
      this.$refs.comparingFilter.setProductLineSelectionType(this.$refs.currentFilter.productLineSelectionType);
      this.$refs.comparingFilter.setFilterKinds(this.$refs.currentFilter.filterKinds);
      this.$refs.comparingFilter.setFilterLevels(this.$refs.currentFilter.filterLevels);
      this.$refs.comparingFilter.setLocationValue(this.$refs.currentFilter.locationType, this.$refs.currentFilter.locationValue());
    },
    collapseTable() {
      this.tableExpanded = false;
      this.userTableExpanded = false;
    },
    expandTable() {
      this.tableExpanded = true;
      this.userTableExpanded = true;
    },
    hasChart(chartName) {
      if (chartName in this.chartsMap) {
        return true;
      }
      return false;
    },
    canExpandChart(chartName) {
      return this.chartClass(chartName) == 'col-md-6';
    },
    canCollapseChart(chartName) {
      return this.chartClass(chartName) == 'col-md-12';
    },
    chartClass(chartName) {
      if (chartName in this.chartsClassesMap) //quando o grafico vai estar aqui? -> somente quando for setado ou escondido
        //como colocar hidden
        return this.chartsClassesMap[chartName];
      return `col-md-${this.colConfig}`;
    },
    hideAllCharts() {
      //se setar todos como hidden, nao tem como manter o estado entre duas execucoes!
      _.forEach(this.allCharts, (entry) => {
        Vue.set(this.chartsClassesMap, entry, 'hidden');
      });
    },
    showChart(chartName) {
      Vue.delete(this.chartsClassesMap, chartName);
    },
    closeChart(chartName) {
      Vue.set(this.chartsClassesMap, chartName, 'hidden');
    },
    collapseChart(chartName) {
      Vue.set(this.chartsClassesMap, chartName, 'col-md-6');
      if (!this.lineCharts) {
        this.$refs[chartName].setDrawValues(false);
        this.$nextTick(() => {
          this.$refs[chartName].updateChart();
        });
      }
    },
    expandChart(chartName) {
      Vue.set(this.chartsClassesMap, chartName, 'col-md-12');
      if (!this.lineCharts) {
        if (_.includes(this.barCharts, chartName) && this.barsValues) {
          this.$refs[chartName].setDrawValues(true, 12, 'bold');
        } else {
          this.$refs[chartName].setDrawValues(false);
        }
        this.$nextTick(() => {
          this.$refs[chartName].updateChart();
        });
      }
    },
    setLineCharts() {
      this.lineCharts = true;

      if (this.hasChartData()) {
        this.loading = true;
        setTimeout(() => {
          this.updateChartsType();
        }, 50);
      }
    },
    setBarCharts() {
      this.lineCharts = false;
      if (this.hasChartData()) {
        this.loading = true;
        setTimeout(() => {
          this.updateChartsType();
        }, 50);
      }
    },
    consolidatedCharts() {
      this.setColConfig(6);
    },
    expandedCharts() {
      this.setColConfig(12);
    },
    setColConfig(value) {
      this.loading = true;
      setTimeout(() => {
        this.colConfig = value;
        this.chartsClassesMap = {};
        if (!this.lineCharts) {
          this.setDrawValuesAllCharts();
        }
        this.loading = false;
      }, 50);
    },
    toggleBarsValues() {
      this.barsValues = !this.barsValues;
      this.setDrawValuesAllCharts();
    },
    toggleMovelMean() {
      this.loading = true;
      setTimeout(() => {
        this.movelMean = !this.movelMean;
        this.updateChartsType();
        this.loading = false;
      }, 50);
    },
    hasChartData() {
      return Object.keys(this.chartsMap).length > 0;
    },
    updateChartsType() {
      if (this.hasChartData()) {
        _.forEach(Object.keys(this.chartsMap), (chartName) => {
          if (chartName in this.$refs) {
            this.$refs[chartName].clearSeries();
            this.renderChart(chartName);
          }
        });

        this.$nextTick(() => {
          _.forEach(Object.keys(this.chartsMap), (chartName) => {
            if (chartName in this.$refs) {
              this.$refs[chartName].updateChart();
            }
          });
          this.loading = false;
        });
      }
    },
    //query string
    dumpQueryString() {
      let filter = this.filterMap(true);

      if (!_.isNil(filter)) {
        let queryString = '?currentFilter=' + JSON.stringify(filter['currentFilter']) + '&comparingMode=' + this.comparingMode.type;
        if (!_.isNil(filter['comparingFilter'])) {
          queryString = queryString + '&comparingFilter=' + JSON.stringify(filter['comparingFilter']);
        }
        if (!_.isNil(filter['grouping'])) {
          queryString = queryString + '&grouping=' + JSON.stringify(filter['grouping']);
        }
        queryString = queryString + '&exibitionType=' + this.exibitionType;
        window.history.pushState('', '', window.location.pathname + queryString);
      }
    },
    // setFiltersData(filter, data) {
    //   let parsedFilters = _.map(data['baseFilters'], (entry) => {
    //     let filteredType = _.filter(this.$refs.comparingFilter.groupOptions, (filterEntry) => {
    //       return filterEntry.type == entry.type;
    //     })
    //     let cloneType = _.cloneDeep(filteredType[0]);
    //     if (entry.type == 'universities') {
    //       cloneType.value = this.solveEntries(this.$refs.currentFilter.universityOptions, entry.value, 'id')
    //     } else if (entry.type == 'group') {;
    //       cloneType.value = this.solveEntry(this.$refs.currentFilter.universityGroupOptions, entry.value.id, 'id')
    //     } else if (entry.type == 'deal_owner' || entry.type == 'deal_owner_ies') {
    //       cloneType.value = this.solveEntry(this.$refs.currentFilter.dealOwnerOptions, entry.value.id, 'id')
    //     } else if (entry.type == 'account_type') {
    //       cloneType.value = this.solveEntry(this.$refs.currentFilter.accountTypeOptions, entry.value.id, 'id')
    //     } else if (entry.type == 'quality_owner' || entry.type == 'quality_owner_ies') {
    //       cloneType.value = this.solveEntry(this.$refs.currentFilter.qualityOwnerOptions, entry.value.id, 'id')
    //     } else if (entry.type == 'farm_region') {
    //       cloneType.value = this.solveEntry(this.$refs.currentFilter.farmRegionOptions, entry.value.id, 'id')
    //     }
    //     return cloneType;
    //   });
    //   filter.setPrimaryFilters(parsedFilters);
    //   if (!_.isNil(data['initialDate']) && !_.isNil(data['finalDate'])) {
    //     filter.setDateRange([moment(data['initialDate']).toDate(), moment(data['finalDate']).toDate()]);
    //   }
    //   if (!_.isNil(data['kinds'])) {
    //     filter.setFilterKinds(this.solveEntries(this.$refs.currentFilter.kindOptions, data['kinds'], 'id'));
    //   }
    //   if (!_.isNil(data['levels'])) {
    //     filter.setFilterLevels(this.solveEntries(this.$refs.currentFilter.levelOptions, data['levels'], 'id'));
    //   }
    //   if (!_.isNil(data['productLine'])) {
    //     filter.setProductLineFilter(this.solveEntry(this.$refs.currentFilter.productLineOptions, data.productLine.id, 'id'))
    //   }
    //   if (!_.isNil(data['productLineSelectionType'])) {
    //     filter.setProductLineSelectionType(data['productLineSelectionType']);
    //   }
    //   if (!_.isNil(data['locationValue']) && !_.isNil(data['locationType'])) {
    //     let locationData = data['locationValue'];
    //     if (data['locationType'] == 'city') {
    //       locationData = {
    //         "name": `${locationData['name']} - ${locationData['state']}`,
    //         "id": locationData['name'],
    //         "state": locationData['state']
    //       }
    //     }
    //     filter.setLocationValue(this.solveEntry(this.$refs.currentFilter.locationOptions, data['locationType'], 'type'), locationData);
    //   }
    // },
    //TODO - base de codigo comum?
    // solveEntries(options, compareValues, field) {
    //   let filters = _.map(compareValues, (valueEntry) => {
    //     let filteredOptions = _.filter(options, (filterEntry) => {
    //       return filterEntry[field] == valueEntry[field];
    //     })
    //     if (filteredOptions.length > 0) {
    //       return filteredOptions[0];
    //     }
    //     return null;
    //   });
    //   return filters;
    // },
    // solveEntry(options, compareValue, field) {
    //   let filteredEntry = _.filter(options, (filterEntry) => {
    //     return filterEntry[field] == compareValue;
    //   })
    //   if (filteredEntry.length > 0) {
    //     return filteredEntry[0];
    //   }
    // },
    //========--------=========
    parseQueryString() {
      const urlParams = new URLSearchParams(window.location.search);

      let currentFilter = urlParams.get('currentFilter');
      let comparingMode = urlParams.get('comparingMode');
      let comparingFilter = urlParams.get('comparingFilter');
      let grouping = urlParams.get('grouping');
      let exibitionType = urlParams.get('exibitionType');
      let hasFilter = false;

      if (!_.isNil(exibitionType)) {
        this.exibitionType = exibitionType;
      }

      if (!_.isNil(currentFilter)) {
        currentFilter = JSON.parse(currentFilter);
        this.$refs.currentFilter.setFiltersData(currentFilter);
        hasFilter = true;
      }

      if (!_.isNil(comparingMode)) {
        let filtered = _.filter(this.comparingOptions, (entry) => {
          return entry.type == comparingMode;
        });

        if (filtered.length > 0) {
          this.comparingMode = filtered[0];
        }
      }

      if (!_.isNil(grouping)) {
        grouping = JSON.parse(grouping)
        this.grouping = grouping;

        if (!_.isNil(currentFilter)) {
          let filteredSeries = _.filter(this.seriesSelectionOptions, (entry) => {
            return entry.id == currentFilter['seriesSelection'];
          });
          if (filteredSeries.length > 0) {
            this.seriesSelection = filteredSeries[0];
          }

          let filteredSeriesField = _.filter(this.seriesSelectionFieldOptions, (entry) => {
            return entry.id == currentFilter['seriesSelectionField'];
          });
          if (filteredSeriesField.length > 0) {
            this.seriesSelectionField = filteredSeriesField[0];
          }
        }
      }

      if (!_.isNil(comparingFilter)) {
        comparingFilter = JSON.parse(comparingFilter);
        this.$refs.comparingFilter.setFiltersData(comparingFilter);
      } else {
        //nao tem comparativo!
        //seta o current!!
          //nao depende do tipo de comparativo?
        if (!_.isNil(currentFilter)) {
          this.$refs.comparingFilter.setFiltersData(currentFilter);
        }
      }

      if (hasFilter) {
        this.$nextTick(() => {
          this.update();
        });
      }
    },
    //filters helper
    setInitialFilterData(filterComponent, data) {
      filterComponent.setLevels(data.levels)
      filterComponent.setKinds(data.kinds);
      filterComponent.setLocations(data.locationTypes);
      filterComponent.setGroups(data.groupTypes);
      filterComponent.setAccountTypes(data.accountTypes);
      filterComponent.setUniversities(data.universities);
      filterComponent.setUniversityGroups(data.groups);
      filterComponent.setSemesterRange(data.semesterStart, data.semesterEnd);
      filterComponent.setDealOwners(data.dealOwners);
      filterComponent.setQualityOwners(data.qualityOwners);
      filterComponent.setRegions(data.regions);
      filterComponent.setStates(data.states);
      filterComponent.setProductLines(data.product_lines);
      filterComponent.setFarmRegions(data.farm_regions)
      filterComponent.setCities([]);
      filterComponent.setCampus([]);
    },
    filterMap(ommitValidation) {
      let currentFilter = this.$refs.currentFilter.filterData(ommitValidation);
      if (!currentFilter) {
        console.log("currentFilter vazio");
        return;
      }

      let filter = { currentFilter };
      if (this.comparingMode.type != 'no_compare') {
        if (this.comparingMode.type == 'grouping') {
          filter.grouping = this.grouping;
          filter.currentFilter.seriesSelection = this.seriesSelection["id"];
          filter.currentFilter.seriesSelectionField = this.seriesSelectionField["id"];
        } else {
          let comparingFilter = this.$refs.comparingFilter.filterData(ommitValidation);
          if (!comparingFilter) {
            console.log("comparingFilter vazio");
          } else {
            filter.comparingFilter = comparingFilter;
          }
        }
      }
      filter.comparingMode = this.comparingMode.type;
      return filter;
    },
    //grouping
    filterGroupingOptions(fields) {
      if (!_.isNil(this.grouping)) {
        if (_.includes(fields, this.grouping.id)) {
          this.grouping = null;
        }
      }
      return _.filter(this.groupingOptions, (entry) => {
        return !_.includes(fields, entry["id"]);
      });
    },

    // external calls
    completeLocation(index) {
      let filter = this.$refs.currentFilter;
      if (index == 1)
        filter = this.$refs.comparingFilter;

      filter.setCitiesLoading();
      filter.setCampusLoading();

      console.log("completeLocation# ID: " + index  + " TYPE: " + JSON.stringify(filter.getLocationType()));

      let filterParams = this.filterMap(true);
      if (_.isNil(filterParams)) {
        return;
      }
      filterParams.field = filter.getLocationType().type;
      filterParams.index = index;

      DashboardChannel.push('filterComplete', filterParams).receive('timeout', () => {
        console.log("filterComplete timeout");
      });
    },
    update() {
      let filter = this.filterMap();
      if (_.isNil(filter)) {
        return;
      }

      if (this.exibitionType == 'custom_charts') {
        this.exibitionType = 'all_charts';
      }

      this.dumpQueryString();

      //TODO - como fica a questao das tabelas diferenciadas?
        //devia tratar no backend?

      //this.userTableExpanded = this.tableExpanded;
      this.tableExpanded = false;

      this.clearCharts();
      this.hideAllCharts();

      this.chartsMap = {};
      this.loading = true;
      this.metrics = [];
      this.metricsCompare = null;
      this.exportSelection = null;
      this.metricsNames = this.baseMetrics;
      this.updateEnabled = false;

      DashboardChannel.push('filter', filter).receive('timeout', () => {
        console.log("load timeout");
      });
    },
    loadFilters() {
      DashboardChannel.push('loadFilters').receive('timeout', () => {
        console.log("filters timeout");
      });
    },
    //external returns
    receiveCitiesFilterData(data){
      if (data.index == 0) {
        this.$refs.currentFilter.setCities(data.cities);
      } else {
        this.$refs.comparingFilter.setCities(data.cities);
      }
    },
    receiveCampusFilterData(data){
      if (data.index == 0) {
        this.$refs.currentFilter.setCampus(data.campus);
      } else {
        this.$refs.comparingFilter.setCampus(data.campus);
      }
    },
    receiveFilterData(data) {
      console.log("receiveFilterData");
      this.setInitialFilterData(this.$refs.currentFilter, data);
      this.setInitialFilterData(this.$refs.comparingFilter, data);

      this.baseMetrics = data.baseMetrics;
      this.metricsNames = this.baseMetrics;

      //filtro inicial eh YoY
      this.$refs.comparingFilter.setDateRange([ moment(data.semesterStart).subtract(12, 'months').toDate(), moment(data.semesterEnd).subtract(12, 'months').toDate() ]);

      this.filtersLoading = false;

      this.parseQueryString();
    },
    receiveTableMetrics(data)  {
      this.metricsNames = data.metrics_keys;

      this.seriesNames[0] = this.$refs.currentFilter.baseFiltersCaption();

      if (this.comparingMode.type != 'no_compare') {
        if (this.comparingMode.type == 'year_to_year') {
          this.seriesNames[1] = 'Ano Anterior';
        } else {
          this.seriesNames[1] = this.$refs.comparingFilter.baseFiltersCaption();
        }
      }

    },
    receiveTableData(data) {
      console.log("receiveTableData# data: " + JSON.stringify(data));

      //pode ser que o usuario escondeu?
      if (!_.isNil(this.userTableExpanded)) {
        this.tableExpanded = this.userTableExpanded;
      } else {
        this.tableExpanded = true;
      }

      while (this.metrics.length <= data.metric) {
        this.metrics.push([]);
      }
      let currentSeries = this.metrics[data.metric];
      while (currentSeries.length <= data.index) {
        currentSeries.push({series_name: '-', table: {}});
      }
      currentSeries.splice(data.index, 1, data);

      let otherIndex = 1 - data.metric;
      if (this.metrics.length > otherIndex) {
        if (!_.isNil(this.metrics[otherIndex][data.index])) {
          if (_.isNil(this.metricsCompare)) {
            this.metricsCompare = [];
          }

          while (this.metricsCompare.length <= data.index) {
            this.metricsCompare.push({series_name: '-', table: {}});
          }

          if (!_.isEmpty(this.metrics[otherIndex][data.index].table)) {
            let compareTable = this.calculateRelations(this.metrics[0][data.index].raw_table, this.metrics[1][data.index].raw_table);
            this.metricsCompare.splice(data.index, 1, compareTable);
          }
        }
      }
    },
    calculateRelations(baseTable, compareTable) {
      let metrics = [
        'atraction_rate',
        'success_rate',
        'conversion_rate',
        'initiated_orders',
        'refunds',
        'visits',
        'initiateds',
        'exchangeds',
        'mean_income',
        'mean_ticket',
        'legacy_mean_income',
        'legacy_mean_ticket',
        'income',
        'qap_income',
        'velocimeter',
        'paids',
        'bos',
        'skus',
        'orders_share',
        'paids_share',
        'visits_share'
      ];
      let relations = _.map(metrics, (metric) => {
        console.log("metric: " + metric + " BASE: " + baseTable[metric] + " COMPARE: " + compareTable[metric]);
        let atual = baseTable[metric];
        let comparativo = compareTable[metric];
        if (_.isNil(atual) || _.isNil(comparativo)) {
          return '-';
        }
        let relation = ((atual - comparativo) / comparativo) * 100;
        return relation.toFixed(2);//.replace('.',',');
      })
      console.log("relations: " + JSON.stringify(relations));
      let returnMap = {};
      _.forEach(_.zip(metrics, relations), (entry) => {
        returnMap[entry[0]] = entry[1];
      });
      return returnMap;
    },
    receiveChartData(data) {
      let index = data.index;
      console.log("receiveChartData# index: " + index + " this.chartsKeys: " + JSON.stringify(this.chartsKeys));
      if ('dates' in data) {
        if (index == 0) {
          this.chartsDates = data.dates;
        }
      }
      if ('keys' in data) {
        //pode ser que esteja adicionando chaves!]
        //como saber?
        if (index == 0) {
          this.chartsKeys = data.keys;
        } else {
          this.chartsKeys = this.chartsKeys.concat(data.keys);
        }
      }
      if ('keys_names' in data) {
        if (index == 0) {
          this.chartsKeysNames = data.keys_names;
        } else {
          this.chartsKeysNames = this.chartsKeysNames.concat(data.keys_names);
        }
      }

      console.log("receiveChartData# this.chartsKeys: " + JSON.stringify(this.chartsKeys));

      _.forEach(data.charts, (entry) => {
        if (entry.name in this.$refs) {
          if (entry.name in this.chartsMap) {
            let entryKeys = Object.keys(entry.raw);
            _.forEach(entryKeys, (key) => {
              this.chartsMap[entry.name].raw[key] = entry.raw[key];
              this.chartsMap[entry.name].mean[key] = entry.mean[key];
              this.chartsMap[entry.name].bar[key] = entry.bar[key];
            });
          } else {
            this.chartsMap[entry.name] = entry;
          }
          if (this.chartVisibleForView(entry.name)) {
            Vue.delete(this.chartsClassesMap, entry.name);
            this.renderChart(entry.name);
          } else {
            Vue.set(this.chartsClassesMap, entry.name, 'hidden');
          }
        }
      });

      this.$nextTick(() => {
        _.forEach(data.charts, (entry) => {
          if (entry.name in this.$refs) {
            this.$refs[entry.name].updateChart();
          }
        });
      });

      this.loading = false;
      this.$nextTick(() => {
        if (index === 0) {
          if (this.comparingMode.type == 'no_compare' || this.comparingMode.type == 'grouping') {
            this.updateEnabled = true;
          }
        } else {
          this.updateEnabled = true;
        }
      });
    },
    //====== chart handling
    clearCharts() {
      _.forEach(Object.keys(this.chartsMap), (chartName) => {
        if (chartName in this.$refs) {
          this.$refs[chartName].clearSeries();
          this.$nextTick(() => {
            this.$refs[chartName].updateChart();
          });
        }
      });
    },
    setDrawValuesAllCharts() {
      _.forEach(this.barCharts, (chartName) => {
        if (chartName in this.$refs) {
          if (this.barsValues && this.canCollapseChart(chartName)) {
            this.$refs[chartName].setDrawValues(true, 12, 'bold');
          } else {
            this.$refs[chartName].setDrawValues(false);
          }
          this.$nextTick(() => {
            this.$refs[chartName].updateChart();
          });
        }
      });
    },
    renderChart(chartName) {
      let chartData = this.chartsMap[chartName];

      //pega as chaves e datas. Pode ser que tenha que mudar as datas
      var dates = this.chartsDates;
      if ('dates' in chartData) {
        dates = _.cloneDeep(chartData.dates);
      }
      var keys = this.chartsKeys;
      if ('keys' in chartData) {
        keys = chartData.keys;
      }
      var keysNames = this.chartsKeysNames;
      if ('keysNames' in chartData) {
        keysNames = chartData.keysNames;
      }

      var currentMax = this.groupingMax.id;
      if (currentMax == 0)
        currentMax = 30;

      var currentChartSeries = [];
      var chartType = null;

      if (this.lineCharts) {
        chartType = 'line';
        if (this.movelMean) {
          currentChartSeries = chartData.mean;
          if (chartData.options.no_mean) {
            currentChartSeries = chartData.raw;
          }
        } else {
          currentChartSeries = chartData.raw;
        }
      } else {
        if (chartData.options.no_bar) {
          chartType = 'line';
          // nao pode usar a media?
          if (chartData.options.no_bar_with_mean) {
            currentChartSeries = chartData.mean;
          } else {
            currentChartSeries = chartData.raw;
          }
        } else {
          chartType = 'bar';
          var barData = {};
          var barDates = [];
          //para cada serie de chartData.bar precisa fazer o sample!
          for (var i = 0; i < dates.length; i += (chartData.options.bar_size + 1)) {
            _.forEach(Object.keys(chartData.bar), (key) => {
              if (!(key in barData)) {
                barData[key] = [];
              }
              barData[key].push(chartData.bar[key][i]);
            });
            barDates.push(dates[i]);
          }
          currentChartSeries = barData;
          dates = barDates;
        }
      }

      if (chartType == 'bar') {
        if (this.barCharts.indexOf(chartName) < 0) {
          this.barCharts.push(chartName);
        }
      } else {
        let currentIndex = this.barCharts.indexOf(chartName);
        if (currentIndex >= 0) {
          this.barCharts.splice(currentIndex, 1);
        }
      }

      this.$refs[chartName].setLabels(dates);

      let maximo = keys.length > currentMax ? currentMax : keys.length;
      for (var i = 0; i < maximo; i++) {
        if (chartType == 'line') {
          this.$refs[chartName].setXAxesAutoSkip(true);
          this.$refs[chartName].setDrawValues(false);
          this.$refs[chartName].setPadding({ left: 0, right: 0, top: 0, bottom: 0 });
        } else {
          this.$refs[chartName].setXAxesAutoSkip(false);
          //so seta draw values se tiver no tamanho certo!
          if (this.canCollapseChart(chartName)) {
            this.$refs[chartName].setDrawValues(true, 12, 'bold');
          } else {
            this.$refs[chartName].setDrawValues(false);
          }
          this.$refs[chartName].setXAxesBarPercentage(0.7);
          this.$refs[chartName].setPadding({ left: 0, right: 0, top: 20, bottom: 0 });
        }

        //quando a chave ( keys[i] ) for base ou comparing, poderia colocar o nome aqui na view!
        let keyName = keysNames[i];
        if (keys[i] == 'base') {
          let sufix = this.$refs.currentFilter.baseFiltersCaption();
          keyName = sufix;
        }
        if (keys[i] == 'comparing') {
          if (this.comparingMode.type == 'year_to_year') {
            keyName = 'Ano Anterior';
          } else {
            keyName = this.$refs.comparingFilter.baseFiltersCaption();
          }
          // keyName =  "Valor comparativo";
        }
        this.$refs[chartName].setSeriesWithOptions(i, currentChartSeries[keys[i]], keyName, {type: chartType, borderWidth: 2});

        if (this.beginChartsAtZero) {
          this.$refs[chartName].setYBeginAtZero(true);
        } else {
          this.$refs[chartName].setYBeginAtZero(false);
        }
      }
    },
    ///====== sincronizacao dos campos
    currentKindSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setFilterKinds(data);
    },
    currentProductLineSelectionTypeSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setProductLineSelectionType(data);
    },
    currentProductLineSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setProductLineFilter(data);
    },
    currentLevelSelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setFilterLevels(data);
    },
    currentRangeSelected(data) {
      if (this.comparingMode.type == 'custom_compare' || this.comparingMode.type == 'all_data') {
        this.$refs.comparingFilter.setDateRange(data);
      } else {
        if (this.comparingMode.type == 'previous_period') {
          this.setPreviousPeriod();
        } else {
          this.$refs.comparingFilter.setDateRange([moment(data[0]).subtract(12, 'months').toDate(),moment(data[1]).subtract(12, 'months').toDate()]);
        }
      }
    },
    currentPrimarySelected(data) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      if (this.comparingMode.type == 'all_data') {
        return;
      }
      this.$refs.comparingFilter.setPrimaryFilters(data);
    },
    currentLocationTypeSelected(data, index) {
      if (!_.isNil(data)) {
        if (_.includes(['city', 'campus'], data.type)) {
          this.$nextTick(() => {
            this.completeLocation(index);
          });
        }
      }
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setLocationType(data);
    },
    currentLocationRemoved(type, value) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setLocationValue(type, value);
    },
    currentLocationSelected(type, value) {
      if (this.comparingMode.type == 'custom_compare') {
        return;
      }
      this.$refs.comparingFilter.setLocationValue(type, value);
    },
    // periods manipulation
    setCurrentPeriod() {
      this.$refs.comparingFilter.setDateRange(this.$refs.currentFilter.getDateRange());
    },
    setPreviousPeriod() {
      let dateRange = this.$refs.currentFilter.getDateRange();
      let dataDiff = moment(dateRange[1]).diff(moment(dateRange[0]), 'days') + 1;
      console.log("setPreviousPeriod# dataDiff: " + dataDiff);
      this.$refs.comparingFilter.setDateRange([moment(dateRange[0]).subtract(dataDiff, 'days').toDate(), moment(dateRange[1]).subtract(dataDiff, 'days').toDate()]);
      console.log("setPreviousPeriod# RANGE: " + this.$refs.comparingFilter.getDateRange());
    },
    setPreviousYearPeriod() {
      let dateRange = this.$refs.currentFilter.getDateRange();
      this.$refs.comparingFilter.setDateRange([moment(dateRange[0]).subtract(12, 'months').toDate(),moment(dateRange[1]).subtract(12, 'months').toDate()]);
    },
  },
};
</script>
