const DEBUG = 15;
const INFO  = 10;
const WARN  = 5;
const ERROR = 0;

var logging_level = ERROR;

function set_level(level){
  logging_level = level;
}

function debug(message){
  _print(message, DEBUG, '[DEBUG]: ');
}

function info(message){
  _print(message, INFO, '[INFO]: ');
}

function warn(message){
  Rollbar.warning(message);
  _print(message, WARN, '[WARN]: ');
}

function error(message){
  _print(message, ERROR, '[ERROR]: ');
}

function _print(message, level, prefix){
  if(level <= logging_level){
    if (typeof message === "string")
      console.log(prefix + message);
    else
      console.log(prefix + JSON.stringify(message));
  }
}

export default {
  DEBUG: DEBUG,
  INFO: INFO,
  WARN: WARN,
  ERROR: ERROR,

  set_level: set_level,

  debug: debug,
  info: info,
  warn: warn,
  error: error
};
