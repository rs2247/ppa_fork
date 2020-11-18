import UserApp from "../templates/user-home";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('user-home', UserApp)

 class UserHome {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`home:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.HomeChannel = channel;
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

window.userHome = new UserHome();
