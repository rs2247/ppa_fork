# PPA

Configurações iniciais para executar o projeto usando Docker

## Para configurações nativas ver o arquivo README_OLD.md

## Primeiros passos

* Gerar chave de acesso no git
	* `$ ssh-keygen`
	* Acessar a página do projeto no github
	* Menu/Settings/SSH and GPG keys/New SSH Key/[copiar chave gerada no item 1]/Add SSH Key

## Setup da imagem docker

* Clone do repositório do github: ( utilizar método ssh )

	`$ git clone git@github.com:redealumni/ppa.git `

	`$ cd ppa `

* Build da imagem do docker: ( usar o Dockerfile.dev para desenvolvimento )

	`$ docker image build -t quero/ppa -f Dockerfile.dev . `

	IMPORTANTE: Para utilização da integração com o [`presentation_generator`](https://github.com/redealumni/presentation_generator) é necessário utilizar os BUILD_ARGS generator_shared_path e generator_templates_path no build da imagem que devem apontar respetivamente para os diretórios `shared` e `ppt_templates` da sua versão local do repo.

	`$ docker image build --build-arg generator_shared_path=/data/ppa/shared --build-arg generator_templates_path=/data/ppa/ppt_templates -t quero/ppa -f Dockerfile.dev . `

* Ajuste de usuário para rodar os comandos do docker sem precisar de sudo

	`$ sudo usermod -aG docker [USERNAME]`

	(necessário deslogar e logar novamente para aplicar)

* Copia da configuração padrão ( ajustar se necessário )

        `$ cp config/examples/database_docker.exs.example config/database.exs`


## Preparando a execução

* Subir o container com o docker-compose

	`$ docker-compose up`

* Abrir o shell do container

        `$ docker exec -it quero/ppa bash`

* Instalar as dependencias dentro do container

	`$ mix deps.get`

	`$ npm install`

## Executando o servidor phoenix

* Subir o servidor phoenix ( dentro do shell do container )

	`$ mix phoenix.server`

Agora você deve conseguir visitar [`localhost:4000`](http://localhost:4000) através de seu browser.
