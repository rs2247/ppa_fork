import ComparingApp from "../templates/comparing-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('comparing-panel', ComparingApp)

 class ComparingPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`comparing_panel:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.ComparingChannel = channel;
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

window.comparingPanel = new ComparingPanel();
