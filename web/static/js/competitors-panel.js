import CompetitorsApp from "../templates/competitors-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('competitors-panel', CompetitorsApp)

 class CompetitorsPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`competitors:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.CompetitorsChannel = channel;
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

window.competitorsPanel = new CompetitorsPanel();
