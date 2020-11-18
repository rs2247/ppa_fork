import AnalysisApp from "../templates/analysis-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('analysis-panel', AnalysisApp)

 class AnalisysPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`analysis:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.AnalysisChannel = channel;
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

window.analysisPanel = new AnalisysPanel();
