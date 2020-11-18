import MainApp from "../templates/panel-app";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('panel-app', MainApp)
 class PanelApp {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`panel:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.PanelChannel = channel;
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
 window.panelApp = new PanelApp();
