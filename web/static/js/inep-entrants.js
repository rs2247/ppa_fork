import InepEntrantsApp from "../templates/inep-entrants";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('inep-entrants', InepEntrantsApp)

 class InepEntrants {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`inep:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.InepChannel = channel;
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

window.inepEntrants = new InepEntrants();
