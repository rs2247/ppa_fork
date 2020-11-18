import PricingApp from "../templates/pricing-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('pricing-panel', PricingApp)

 class PricingPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`pricing:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.PricingChannel = channel;
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

window.pricingPanel = new PricingPanel();
