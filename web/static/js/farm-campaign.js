import FarmCampaignApp from "../templates/farm-campaign";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('farm-campaign', FarmCampaignApp)

 class FarmCampaignPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`farm_campaign:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.FarmCampaignChannel = channel;
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

window.farmCampaign = new FarmCampaignPanel();
