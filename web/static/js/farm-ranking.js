import FarmRankingApp from "../templates/farm-ranking-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('farm-ranking-panel', FarmRankingApp)

 class FarmRankingPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`farm_ranking:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.FarmRankingChannel = channel;
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

window.farmRankingPanel = new FarmRankingPanel();
