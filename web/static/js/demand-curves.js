import DemandCurvesApp from "../templates/demand-curves";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('demand-curves', DemandCurvesApp)

 class DemandCurvesPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`demand_curves:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.DemandCurvesChannel = channel;
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

window.demandCurvesPanel = new DemandCurvesPanel();
