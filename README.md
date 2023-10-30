# atividade2-docker-AWS

<p align="center">
  <img src="https://github.com/rvinii/atividade2-docker-AWS/assets/87549312/8bb028f0-91ed-43e8-ab96-483b47a53a3d" width="340px">
</p>


###  Sobre a Atividade

1. Instalação e configuração do DOCKER ou CONTAINERD no host EC2.
  * Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)

2. Efetuar Deploy de uma aplicação Wordpress com: 
  * Container de aplicação
  * RDS database MySQL

3. Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação WordPress

4. Configuração do serviço de Load Balancer AWS para a aplicação Wordpress

   ![image](https://github.com/rvinii/atividade2-docker-AWS/assets/87549312/50d6bd88-e6dc-4d09-8232-8d3a2ffd1409)

<div align="center">
   <p><em>Arquitetura</em></p>
</div>

## Security Groups - Criação

Primeiramente, o passo inicial é criar os security groups para cada serviço da AWS.

SG PUBLIC
| Tipo                            | Protocolo | Porta | Origem         |
|---------------------------------|-----------|-------|----------------|
| SSH                             | TCP       | 22    | 0.0.0.0/0      |
| HTTP                            | TCP       | 80    | 0.0.0.0/0      |
| Todos os ICMPs - IPv4           | ICMP      | TUDO  | 0.0.0.0/0      |


SG PRIVATE (destinado às instâncias EC2)

| Tipo  | Protocolo | Porta | Origem   |
|-------|-----------|-------|----------|
| SSH   | TCP       | 22    | SG-PUBLIC|
| HTTP  | TCP       | 80    | SG-PUBLIC|


SG DO EFS
| Tipo   | Protocolo | Porta | Origem     |
|--------|-----------|-------|------------|
| NFS    | TCP       | 2049  | SG-PRIVATE |


SG DO RDS
| Tipo            | Protocolo | Porta | Origem     |
|-----------------|-----------|-------|------------|
| MYSQL/AURORA    | TCP       | 3306  | SG-PRIVATE |


## CRIANDO A VPC

Agora partimos para a criação da VPC. Para isso, abra o menu de criação de VPC no seu console AWS, abaixo de "Your VPCs" selecione a opção “subnets”, e crie duas subnets públicas e duas privadas em duas zonas diferentes. Em seguida, configure o “Route Table” para direcionar as subnets públicas para o “Internet Gateway” e crie outra “Route Table” para apontar as subnets privadas para o “NAT Gateway”.

  Em seguida, crie a VPC e associe as sub-redes, tabela de rotas e as conexões de rede.

![image](https://github.com/rvinii/atividade2-docker-AWS/assets/87549312/7efbe1e0-91bf-4517-8d93-067a09994954)

<div align="center">
   <p><em>Mapa de Recursos</em></p>
</div>


## Criando o RDS

Na console AWS, procure pelo serviço RDS, em seguida clique em “Criar Banco de Dados” e escolha as configurações do seu banco de dados.

![image](https://github.com/rvinii/atividade2-docker-AWS/assets/87549312/699abefd-bbf5-43af-8927-fcfa9d3e8d0b)

<div align="center">
   <p><em>Configurações de criação do RDS</em></p>
</div>

O ponto de atenção na criação do banco de dados é:
- **Nome do banco de dados**
- **Usuário e senha para acessar o banco de dados**

Em “Conectividade” selecione a VPC criada anteriormente, a sub-rede e o security group que criamos para o RDS.


## Criação do EFS

Na console AWS, procure pelo serviço EFS. Clique em “Criar sistema de arquivo”, dê um nome e selecione a VPC que criamos, depois clique em “Personalizar”, verifique as configurações e clique em próximo. Selecione a VPC que criamos e selecione as sub-redes, siga e finalize a criação.


## Criando o Bastion Host

Temos que  um dos requisitos da atividade é não utilizar IP público na instância e somente realizar o acesso a aplicação WordPress por meio de um Load Balancer. Sendo assim,  a solução mais adequada para este caso é a criação de um Bastion Host na AWS (Amazon Web Services) com o uso de um Load Balancer para acessar a aplicação na instância privada. 

  Na console AWS, procure pelo serviço EC2 e clique em “Executar instância”, nomeie a instância como “Bastion Host” e siga com as configurações da instância (Sistema Operacional, tipo de instância, chave), e em seguida selecione o Grupo de Segurança Público que criamos anteriormente e inicie a instância.


## Criação do Load Balancer
Na console AWS, procure pelo serviço EC2, no painel de navegação à esquerda, clique em "Load Balancers", depois clique em "Criar Load Balancer" para iniciar o assistente de criação.Em seguida, escolha o tipo de load balancer: Selecione "Application Load Balancer" como o tipo de load balancer. Depois configure o Load Balancer: 

1. Dê um nome ao LB.
2. Selecione a VPC que criamos.
3. Selecione as sub-redes que serão implantadas no LB. 
4. Selecione o Grupo de Segurança.
5. Em Listener e roteamento, lembre-se de configurar o grupos de destino(Target Group), crie-o (caso ainda não tenha sido criado).
6. Depois clique em “Criar load balancer”

## Criando Modelo de execução
Antes de criar um Auto Scaling, podemos criar um modelo de execução para ser adicionado ao Auto Scaling para orientá-lo de como devem ser as instâncias EC2 que ele deve “Criar”. 
Na console AWS, procure pelo serviço EC2, no painel de navegação à esquerda, clique em "Modelos de Execução", depois clique em "Criar modelo de execução" para iniciar o assistente de criação. Após isso, faça o processo como se fosse a criação de uma instância normal. No entanto, temos que nos atentar aos requisitos da atividade, colocando a instância no grupo de segurança privado. 


Após todo o processo de configuração do modelo, quase no fim da página, clique em “Detalhes Avançados”, teremos um espaço em branco para adicionar o nosso script ou fazer upload de um arquivo, neste caso optei por colar o script no espaço em branco. Dessa forma, ao iniciar a instância o script irá rodar e instalar e configurar toda a infraestrutura, instalando Docker, execução dos containers,  NFS, Wordpress, etc.

Criando um Auto Scaling
Na console AWS, procure pelo serviço EC2, no painel de navegação à esquerda, clique em "Grupos Auto Scaling", depois clique em "Criar grupo Auto Scaling" para iniciar o assistente de criação. Em seguida, defina um nome e escolha o modelo de execução que criamos anteriormente. Lembre-se de selecionar a nossa VPC e as zonas de disponibilidades e sub-redes, vale ressaltar que devemos escolher as sub-redes privadas, pois elas serão destinadas às instâncias. Após isso, anexe o nosso Load Balancer que criamos. 


Importante salientar que devemos nos atentar ao “tamanho do grupo”, a quantidade de  instâncias que desejamos criar devem ser definidas aqui.

![image](https://github.com/rvinii/atividade2-docker-AWS/assets/87549312/0c95ecfd-eee0-4842-bedc-8acabb5ef82f)

<div align="center">
   <p><em>Configurações de criação do Auto Scaling</em></p>
</div>

Por fim,  finalize a criação do Auto Scaling e aguarde a criação das instâncias.


## Criação do arquivo Docker Compose para execução dos containers

[Este arquivo](https://github.com/rvinii/atividade2-docker-AWS/blob/main/docker-compose.yaml)
 representa uma configuração do Docker Compose, elaborada para definir e executar aplicativos em contêineres Docker múltiplos. Para esta atividade, utilizaremos um script para gerenciar uma instância do WordPress e um banco de dados MySQL em contêineres distintos.

```yaml
version: '3.3'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: myrds.c4hbjx2clht3.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: admin123
      WORDPRESS_DB_NAME: myDB
      WORDPRESS_TABLE_CONFIG: wp_
```



## Script user_data.sh

[O script](https://github.com/rvinii/atividade2-docker-AWS/blob/main/user_data.sh) que criei realiza as seguintes ações:



1. **Atualiza o sistema:** Executa `sudo yum update -y` para atualizar o sistema operacional.

2. **Instala o Docker:** Usa `sudo yum install docker -y` para instalar o Docker.

3. **Inicia o Docker e o habilita para iniciar na inicialização:** Executa `sudo systemctl start docker` para iniciar o serviço Docker e `sudo systemctl enable docker` para garantir que ele seja iniciado automaticamente na inicialização.

4. **Instala o utilitário Docker Compose:** Faz o download e instala o Docker Compose, tornando-o executável. Isso permite gerenciar aplicativos Docker com vários contêineres.

5. **Instala o pacote nfs-utils:** Adiciona suporte ao NFS (Network File System).

6. **Cria diretórios:** Cria diretórios `/mnt/efs` e `/home/ec2-user` para uso posterior.

7. **Baixa um arquivo docker-compose.yml:** Faz o download de um arquivo `docker-compose.yml` de um repositório Git e o armazena em `/home/ec2-user/docker-compose.yaml`.

8. **Monta o sistema de arquivos EFS:** Monta o sistema de arquivos Amazon Elastic File System (EFS) usando o endpoint especificado.

9. **Adiciona montagem do EFS ao /etc/fstab:** Configura a montagem do EFS para ser automática na inicialização, adicionando uma entrada no arquivo `/etc/fstab`.

10. **Inicia os serviços com Docker Compose:** Navega até o diretório `/home/ec2-user` e inicia os serviços definidos no arquivo `docker-compose.yml` usando `docker-compose up -d`. Os contêineres são executados em segundo plano (`-d`).


<p align="center">
  <img src="https://github.com/rvinii/atividade2-docker-AWS/assets/87549312/8bb028f0-91ed-43e8-ab96-483b47a53a3d" width="340px">
</p>




