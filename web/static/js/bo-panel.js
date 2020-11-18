import BoApp from "../templates/bo-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('bo-panel', BoApp)

 class BoPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`bo_panel:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.BoChannel = channel;
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

window.boPanel = new BoPanel();
