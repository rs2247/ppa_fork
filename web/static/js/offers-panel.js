import OffersApp from "../templates/offers-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('offers-panel', OffersApp)

 class OffersPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`offers:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.OffersChannel = channel;
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

window.offersPanel = new OffersPanel();
