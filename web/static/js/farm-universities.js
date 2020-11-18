import FarmUniversitiesApp from "../templates/farm-universities";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('farm-universities', FarmUniversitiesApp)

 class FarmUniversities {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`farm_universities:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.FarmUniversitiesChannel = channel;
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

window.farmUniversities = new FarmUniversities();
