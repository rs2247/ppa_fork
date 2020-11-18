import CpfsApp from "../templates/cpfs-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('cpfs-panel', CpfsApp)

 class CpfsPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`cpfs:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.CpfsChannel = channel;
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

window.cpfsPanel = new CpfsPanel();
