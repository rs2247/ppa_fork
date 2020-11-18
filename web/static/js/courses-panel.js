import CoursesApp from "../templates/courses-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('courses-panel', CoursesApp)

 class CoursesPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`courses:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.CoursesChannel = channel;
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

window.coursesPanel = new CoursesPanel();
