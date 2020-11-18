import QualityApp from "../templates/quality-stats";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('quality-stats', QualityApp)

 class QualityStats {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`quality_stats:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.QualityStatsChannel = channel;
      console.log("channel joined. loaded: " + this.loaded);
      if (!this.loaded) {
        this.loaded = true;
        window.vueApp = new Vue({
          el: '#app',
          mounted() {
            console.log("app ready");
          },
        });
      }
    }, { capturePeriod });

  }
}

window.qualityStats = new QualityStats();
