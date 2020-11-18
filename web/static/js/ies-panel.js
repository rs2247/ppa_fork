import IesApp from "../templates/ies-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('ies-panel', IesApp)

 class IesPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`ies:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.IesChannel = channel;
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

window.iesPanel = new IesPanel();
