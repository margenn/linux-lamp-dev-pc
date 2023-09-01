## LINUX UBUNTU 20.04 LAMP/LEMP DEV SERVER

### Passo a Passo: Como configurar um ambiente de desenvolvimento [LAMP](https://en.wikipedia.org/wiki/LAMP_%28software_bundle%29)/[LEMP](https://lemp.io/) no Ubuntu 20.04 com:

- MYSQL8.0
- MYSQL5.7
- PHP7.4
- PHP8.0
- APACHE
- NGINX
- XDEBUG
- VSCODE
- LAMPCONFIG.SH (Configurador de stack)

&nbsp;<br />
## INTRODUÇÃO

&nbsp;<br />
Após seguir as instruções, será possível montar um ambiente que permite mudar o stack de desenvolvimento com uma linha de comando, como neste exemplo:
```console
sudo lampconfig.sh "NGINX PHP7.4 MYSQL5.7"
```
Ou ainda:
```console
sudo lampconfig.sh "APACHE PHP8.0 MYSQL8.0"
```
Diferente das soluções baseadas em container, aqui, as aplicações são instaladas de forma nativa. O controle é feito pelo script **lampconfig.sh**.
