import FarmKeyAccountsApp from "../templates/farm-key-accounts";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('farm-key-accounts', FarmKeyAccountsApp)

 class FarmKeyAccounts {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`farm_key_accounts:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.FarmKeyAccountChannel = channel;
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

window.farmKeyAccounts = new FarmKeyAccounts();
