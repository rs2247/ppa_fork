import QualiApp from "../templates/quali-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('quali-panel', QualiApp)

 class QualiPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`quality:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.QualiChannel = channel;
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

window.qualiPanel = new QualiPanel();
