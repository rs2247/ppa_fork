import RefundApp from "../templates/refund-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('refund-panel', RefundApp)

 class RefundPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`refund_panel:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.RefundChannel = channel;
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

window.refundPanel = new RefundPanel();