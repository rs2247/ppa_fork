import IesStatsApp from "../templates/ies-stats";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('ies-stats', IesStatsApp)

 class IesStats {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`ies_stats:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.IesStatsChannel = channel;
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

window.iesStats = new IesStats();
