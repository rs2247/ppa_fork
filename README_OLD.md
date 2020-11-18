# Ppa

Partnerships Panel

## Configuração do ambiente de desenvolvimento

### Intalação do Postgres

* No Ubuntu:
  * Coloque `deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main` em `/etc/apt/sources.list.d/pgdg.list`
  * Execute os seguintes comandos:
    * `$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -`
    * `$ sudo apt-get update && sudo apt-get -y upgrade`
    * `$ sudo apt-get install postgresql-9.6 postgresql-contrib-9.6 libpq-dev`
* No Mac:
  * Recomenda-se utilizar o Postgres.app, um bundle (aplicativo instalável) nativo do Mac. Basta baixar e mover para a pasta de Aplicações do sistema.
  * Utilize a versão 9.6.x

O banco de dados deve ser iniciado manualmente sempre que necessário, iniciando o aplicativo instalado.

### Instalação do Erlang e do Elixir

* No Ubuntu:
  * Execute os seguintes comandos:
    * `$ wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb`
    * `$ sudo apt-get update`
    * `$ sudo apt-get install esl-erlang`
    * `$ sudo apt-get install elixir`
> Verifique se no arquivo `/etc/apt/sources.list.d/erlang-solutions.list` tem a seguite linha: `deb http://binaries.erlang-solutions.com/debian <version> contrib`

* No Mac:
  * Execute os seguintes comandos:
  * `$ brew update`
    * `$ brew install elixir`

### Instalação do Node.js

* No Ubuntu:
  * Execute os seguintes comandos:
    * `$ curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -`
    * `$ sudo apt-get install nodejs`
* No Mac:
  * Execute os seguintes comandos (assumindo que você possui o `homebrew` instalado):
    * `$ brew update`
    * `$ brew install node`
  * Você também pode baixar o instalador do site oficial: https://nodejs.org/en/download/

## Para instalar e iniciar o Ppa:

* clone o projeto `$ git clone git@github.com:redealumni/ppa.git && cd ppa`
* Instale as dependências com `$ mix deps.get`
* Configure o banco de dados:
  * Copie o arquivo `config/examples/database.exs.example` para `config/database.exs`
  * Edite o arquivo `config/database.exs` para incluir suas informações de `username` e `password` no banco.
  * Crie a pasta `priv/repo/migrations`
  * Faça o download das dependências do projeto utilizando `mix deps.get`
  * Crie e migre o banco de dados com `$ mix ecto.create && mix ecto.migrate -r Ppa.Repo`
    * Caso o comando `$ mix ecto.migrate -r Ppa.Repo` dê problema com a extensão `dblink`, execute os seguintes passos:
      - Rode `$ psql -d querobolsa_development -U SEU_USUARIO`
      - No `psql` rode `CREATE EXTENSION dblink;`
      - Saia do `psql` e rode de novo `$ mix ecto.migrate -r Ppa.Repo`
* Instale as dependências do Node.js com `$ npm install`
* Inicie o endpoint do Phoenix com `$ mix phoenix.server`

Agora você deve conseguir visitar [`localhost:4000`](http://localhost:4000) através de seu browser.


## Migrações

Para criar uma nova migração
* `$ mix ecto.gen.migration nome_da_migracao -r Ppa.Repo`

Para aplicar novas migrações
* `$ mix ecto.migrate -r Ppa.Repo`


## Deployment

O PPA está em uma máquina virtual no servidor do BI; o deploy é feito através de uma integração automática com o github. Quando um PR é mergeado na branch `master`, o deploy acontece automaticamente.

## Testes

```
MIX_ENV=test mix test
```

## Documentação

```
mix docs
```
