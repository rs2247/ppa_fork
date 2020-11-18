# Configuração de deploy
Este tutorial explicita os passos necessários para configuar o deploy do PPA em uma máquina UBUNTU (ou outro projeto Phoenix) utilizando uma lib chamada [Gatling](https://github.com/hashrocket/gatling).

> Nota: esse tutorial supõe que a máquina possui as configuração básicas do projeto. Consulte no README.md desse projeto a configuração do ambiente de desenvolvimento.

## Configurações no servidor

Logar no servidor, e.g.
```
ssh -i "chave.pem" deploy@farm.lan
```

Criar um usuário e senha para o psql, e.g. usuário e senha `deploy`
```
sudo -i -u postgres
createuser --interactive --pwprompt
deploy
deploy
deploy
y
```

```
sudo -u postgres createdb deploy`
sudo visudo -f /etc/sudoers.d/deploy
  * deploy  ALL=(ALL) NOPASSWD:ALL
```


Exportar as seguintes variáveis de ambiente:
> Atenção para os valores entre `<` e `>`, que devem ser alterados para corresponder ao seu ambiente.

```
echo 'MIX_ENV=prod' | sudo tee -a /etc/environment
echo 'SECRET_KEY_BASE=EyzEYA3mMgnDLpQCPk3N2GVJ6XSZrplUlFLE1rRokVSPVZV6LwdJMrvHkV8WmMeU' | sudo tee -a /etc/environment
echo 'DB_QB_HOSTNAME=<DB_QB_HOSTNAME>' | sudo tee -a /etc/environment
echo 'DB_QB_DATABASE=querobolsa_production' | sudo tee -a /etc/environment
echo 'DB_QB_USERNAME=<DB_QB_USERNAME>' | sudo tee -a /etc/environment
echo 'DB_QB_PASSWORD=<DB_QB_PASSWORD>' | sudo tee -a /etc/environment

echo 'DB_HOSTNAME=<DB_HOSTNAME>' | sudo tee -a /etc/environment
echo 'DB_DATABASE=developer' | sudo tee -a /etc/environment
echo 'DB_USERNAME=<DB_USERNAME>' | sudo tee -a /etc/environment
echo 'DB_PASSWORD=<DB_PASSWORD>' | sudo tee -a /etc/environment

source /etc/environment
```

Instalar o nginx e o git:
```
sudo apt-get install nginx git
```

Instalar o Gatling:
```
mix archive.install https://github.com/hashrocket/gatling_archives/raw/master/gatling.ez
mix local.hex
mix local.rebar
```

Criar um repositório e um diretório de deployments com o Gatling:
```
mix gatling.load ppa
```

Descomentar a seguinte linha em `/etc/nginx/nginx.conf`:
```
# server_names_hash_bucket_size 64;
```
e alterá-la para:
```
server_names_hash_bucket_size 1024;
```

Rodar os comandos abaixo para evitar mensagem de locales do perl (isso é essencial para o funcionamento do deployment)
```
echo 'export LC_CTYPE=en_US.UTF-8' | sudo tee -a /etc/environment
echo 'export LC_ALL=en_US.UTF-8'   | sudo tee -a /etc/environment
source /etc/environment
```

## Configurações locais

Em uma janela de terminal local, adicione o remote da produção / stating no git
```
git remote add production deploy@farm.lan:ppa
git push production master
```

## Primeiro deploy no servidor

Logue novamente no servidor e crie um arquivo 'domains' na pasta raiz do projeto, com a url do servidor de produção / staging, e.g.
```
farm.lan
```

É preciso fazer o primeiro deploy manualmente no servidor, executando o seguinte comando:
```
sudo mix gatling.deploy ppa
```

A partir dai, basta executar localmente o comando
```
git push production master
```
para fazer o deploy do master.

O terminal irá exibir o output da compilação do código, migração, e redeploy.

## Mudando o domínino

Caso você queira mudar o domínio da aplicação (e.g. de `ppa-staging.querobolsa.com.br` para `ppa-staging.querobolsa.space`), logue na máquina respectiva e siga os seguintes passos:

Pare os serviços relacionados e remova a configuração atual do nginx para a s aplicação, e.g.

```
sudo service nginx stop
sudo service ppa stop
sudo rm /etc/init.d/ppa
sudo rm /etc/nginx/sites-available/ppa
```

Altere o arquivo domains, que se encontra na raiz do projeto, para referenciar o novo domínio, e.g.

```
echo 'novo-dominio.com' > ppa/domains
```

Execute o comando de deploy manual novamente:

```
sudo mix gatling.deploy ppa
```

Também pode ser necessário rodar:
```
sudo service nginx restart
```
