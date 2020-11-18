import SoldCoursesApp from "../templates/sold-courses-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('sold-courses-panel', SoldCoursesApp)

 class SoldCoursesPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`sold_courses:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.SoldCoursesChannel = channel;
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

window.soldCoursesPanel = new SoldCoursesPanel();
