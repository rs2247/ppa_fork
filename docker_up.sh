docker rm -f ppa
docker run -it -p 7000:4000 -v /home/yves/coded/ppa:/ppa -v /home/yves/.ppa_cache/root:/root -v /home/yves/.ppa_cache/node:/ppa/node_modules -v /home/yves/.ppa_cache/deps:/ppa/deps -v /home/yves/.ppa_cache/_build:/ppa/_build --name ppa quero/ppa bash -c "/ppa/start_docker.sh"
