#!/bin/bash
username=''
host=''
path=''

#Getting flags
while getopts 'u:h:p:' flag; do
  case "${flag}" in
    u) username=$OPTARG ;;
    h) host=$OPTARG ;;
    p) path=$OPTARG ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

ssh "$username@$host" -t "
  cd ~/$path &&
  echo Cloning Repository &&
  git clone -b ppa_staging https://github.com/redealumni/ppa.git &&
  cd ppa &&
  echo Building Image &&
  docker image build -t quero/ppa . &&
  echo Starting Container &&
  docker run -p 4000:4000 --name ppa quero/ppa mix phoenix.server
"
