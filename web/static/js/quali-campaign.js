import QualiCampaignApp from "../templates/quali-campaign";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('quali-campaign', QualiCampaignApp)

 class QualiCampaignPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`quali_campaign:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.QualiCampaignChannel = channel;
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

window.qualiCampaign = new QualiCampaignPanel();
