import StockApp from "../templates/stock-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('stock-panel', StockApp)

 class StockPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`stock:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.StockChannel = channel;
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

window.stockPanel = new StockPanel();
