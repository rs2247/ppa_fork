import MainApp from "../templates/dashboard";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('dashboard', MainApp)

 class DashboardApp {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`dashboard:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.DashboardChannel = channel;
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
 window.dashboardApp = new DashboardApp();
