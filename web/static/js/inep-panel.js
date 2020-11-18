import InepApp from "../templates/inep-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('inep-panel', InepApp)

 class InepPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`inep_panel:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.InepPanelChannel = channel;
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

window.inepPanel = new InepPanel();
