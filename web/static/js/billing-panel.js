import BillingApp from "../templates/billing-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('billing-panel', BillingApp)

 class BillingPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`billing:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.BillingChannel = channel;
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

window.billingPanel = new BillingPanel();
