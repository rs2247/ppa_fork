import FunnelApp from "../templates/funnel-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('funnel-panel', FunnelApp)

 class FunnelPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`funnel_panel:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.FunnelChannel = channel;
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

window.funnelPanel = new FunnelPanel();
