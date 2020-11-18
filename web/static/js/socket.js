// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import { Socket } from "phoenix";
import fetchToken from "./token";
import Logging from "./logging";

let token = fetchToken()
let socket = new Socket("/socket", {
  params: {
    token: token
  }
});
socket.connect();

export { socket };

export function joinSingleChannel(identification, type, callback, params) {
  let channel = socket.channel(identification, params)
  channel.join().receive("ok", resp => {
    console.log("Joined successfully " + type, resp);
    callback(type, channel, resp);
  }).receive("error", resp => {
    console.log("Unable to join " + type, resp);
  });
}
