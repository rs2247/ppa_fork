import SearchRankingApp from "../templates/search-ranking-panel";
import { socket, joinSingleChannel } from "./socket"

 Vue.component('search-ranking-panel', SearchRankingApp)

 class SearchRankingPanel {
   setup() {
    this.setupComponent();
    this.loaded = false;
  }
   setupComponent() {
    const capturePeriod = document.getElementById("capture-period").value;
    const channelHash = document.getElementById("channel-hash").value;
    joinSingleChannel(`search_ranking:data:${channelHash}`, "panel", (channel_type, channel, params) => {
      window.SearchRankingChannel = channel;
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

window.searchRankingPanel = new SearchRankingPanel();
