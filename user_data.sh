#!/bin/bash

# Atualize o sistema
sudo yum update -y

# Instale o Docker
sudo yum install docker -y

# Inicie o Docker e habilite-o para iniciar na inicialização
sudo systemctl start docker
sudo systemctl enable docker

# Instale o utilitário de gerenciamento de contêineres Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose

# Instale o pacote nfs-utils para suporte ao NFS
sudo yum install nfs-utils -y
sudo systemctl enable nfs-server
sudo systemctl start nfs-server


# Crie diretórios
sudo mkdir -p /mnt/efs
sudo mkdir -p /home/ec2-user

# Baixe o arquivo docker-compose.yml do repositório Git
sudo curl -sL "https://raw.githubusercontent.com/rvinii/atividade2-docker-AWS/main/docker-compose.yaml" --output "/home/ec2-user/docker-compose.yaml"

# Montagem do sistema de arquivos EFS
EFS_ENDPOINT="fs-088519e51420ab96c.efs.us-east-1.amazonaws.com"
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "$EFS_ENDPOINT:/mnt/efs" /mnt/efs
sudo chown ec2-user:ec2-user /mnt/efs

# Adicione a montagem do EFS ao /etc/fstab para montagem automática na inicialização
echo "$EFS_ENDPOINT:/ /mnt/efs nfs defaults 0 0" | sudo tee -a /etc/fstab

# Inicie os serviços com Docker Compose
cd /home/ec2-user
docker-compose up -d
