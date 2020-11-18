import CrawlerApp from "../templates/crawler-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('crawler-panel', CrawlerApp)

 class CrawlerPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`crawler:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.CrawlerChannel = channel;
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

window.crawlerPanel = new CrawlerPanel();
