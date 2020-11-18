import PaidsApp from "../templates/paids-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('paids-panel', PaidsApp)

 class PaidsPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`paids:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.PaidsChannel = channel;
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

window.paidsPanel = new PaidsPanel();
