import SearchSimulatorApp from "../templates/search-simulator";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('search-simulator', SearchSimulatorApp)

 class SearchSimulatorPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`search_simulator:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.SearchSimulatorChannel = channel;
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

window.searchSimulatorPanel = new SearchSimulatorPanel();
