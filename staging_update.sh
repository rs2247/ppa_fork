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
  cd ~/$path/ppa &&
  echo Stopping Container &&
  docker rm -f ppa
  echo pulling changes &&
  git pull origin ppa_staging &&
  echo Creating new Image &&
  docker image build -t quero/ppa . &&
  echo Starting Container &&
  docker run -p 4000:4000 --name ppa quero/ppa mix phoenix.server
"
