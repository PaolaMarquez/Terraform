resource "digitalocean_droplet" "web" {
  image = "ubuntu-23-10-x64"
  name = var.name_project
  region = var.region
  size = var.size
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

    provisioner "remote-exec" {
    inline = [
            #Firewall
            "sudo apt-get update",
            "sudo ufw default deny incoming",
            "sudo ufw default allow outgoing",
            "sudo ufw allow OpenSSH",
            "echo 'y' | sudo ufw enable",

            #Add User
            "sudo adduser --gecos '' --disabled-password myuser && echo 'myuser:${var.password}' | sudo chpasswd",
            "sudo usermod -aG sudo myuser",
            "su - myuser",

            #Git
            "git clone ${var.github_link}",

            #Docker
            "echo ${var.password} | sudo -S apt update",
            "echo ${var.password} | sudo -S DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates curl software-properties-common",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
            "echo ${var.docker_link} | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
            "echo ${var.password} | sudo -S apt update",
            "sudo DEBIAN_FRONTEND=noninteractive apt install -y docker-ce",
            "sudo usermod -aG docker myuser",
            "echo ${var.password} | su - myuser",

            #Docker Compose
            "mkdir -p ~/.docker/cli-plugins/ && curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",  #REVISAR
            "chmod +x ~/.docker/cli-plugins/docker-compose",
            "echo ${var.password} | sudo -S bash -c 'cd ${var.github_repo}; docker compose up -d'",

            #Domain
            "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ${var.do_token}' -d '{\"type\":\"A\",\"name\":\"${var.github_repo}\",\"data\":\"${self.ipv4_address}\",\"priority\":null,\"port\":null,\"ttl\":3600,\"weight\":null,\"flags\":null,\"tag\":null}' 'https://api.digitalocean.com/v2/domains/${var.domain}/records'",
            "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ${var.do_token}' -d '{\"type\": \"CNAME\",\"name\": \"www.${var.github_repo}\",\"data\": \"${var.github_repo}.\",\"priority\":null,\"port\":null,\"ttl\":1800,\"weight\":null,\"flags\":null,\"tag\":null}' 'https://api.digitalocean.com/v2/domains/${var.domain}/records'",
            
            #Nginx
            "echo ${var.password} | sudo -S apt update",
            "sudo DEBIAN_FRONTEND=noninteractive apt install -y nginx",
            "sudo ufw app list",
            "echo ${var.password} | sudo -S ufw allow 'Nginx Full'",

            #Nginx Config
            "sudo touch /etc/nginx/sites-available/exercisediary.deploy-tap.site",
            "echo 'server { listen 80; server_name ${var.github_repo}.${var.domain} www.${var.github_repo}.${var.domain}; location / {proxy_pass http://${self.ipv4_address}:${var.puerto}/; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection 'upgrade'; proxy_set_header Host $host; proxy_cache_bypass $http_upgrade; proxy_set_header X-Real-IP $remote_addr;} }' > /etc/nginx/sites-available/${var.github_repo}.${var.domain}",
            "sudo sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/' /etc/nginx/nginx.conf",
            "sudo ln -s /etc/nginx/sites-available/${var.github_repo}.${var.domain} /etc/nginx/sites-enabled/",
            "sudo bash -c 'cd /etc/nginx/sites-enabled; sudo unlink default'",
            "sudo systemctl restart nginx",


            # "sudo ufw allow OpenSSH",
            # "sudo ufw allow http",
            # "sudo ufw allow https",
            # "sudo ufw enable -y",
            # "sudo adduser --disabled-password --gecos '' myuser",
            # "sudo mkdir -p /home/myuser/.ssh",
            # "sudo touch /home/myuser/.ssh/authorized_keys",
            # "sudo echo '${var.pub_key}' > authorized_keys",
            # "sudo mv authorized_keys /home/myuser/.ssh",
            # "sudo chown -R myuser:myuser /home/myuser/.ssh",
            # "sudo chmod 700 /home/myuser/.ssh",
            # "sudo chmod 600 /home/myuser/.ssh/authorized_keys",
            # "sudo usermod -aG sudo myuser",
            # "sudo apt-get -y install nginx",  #instalar nginx
            # "sudo apt update",  #Antes estaba la de Quevedo
            # "${var.command} git clone ${var.github_link}",
            # "sudo apt update", #instalar docker
            # "sudo DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates curl software-properties-common", #saca cuadro morado
            # "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -", #este no tenía sudo
            # "sudo add-apt-repository ${var.docker_link} -y",
            # "sudo apt update",
            # "apt-cache policy docker-ce",
            # "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce", #saca cuadro morado
            # "sudo curl -L ${var.docker_compose_link} -o /usr/local/bin/docker-compose",   #instalar docker compose
            # "sudo chmod +x /usr/local/bin/docker-compose",
            # "sudo usermod -aG docker myuser",
            # "${var.command} bash -c 'cd ${var.github_repo}; docker build .'",
            # "${var.command} bash -c 'cd ${var.github_repo}; docker run -it -d -p ${var.puerto}:${var.puerto} $(docker images -q | head -n 1)'",
            # "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ${var.do_token}' -d '{\"type\":\"A\",\"name\":\"${var.github_repo}\",\"data\":\"${self.ipv4_address}\",\"priority\":null,\"port\":null,\"ttl\":3600,\"weight\":null,\"flags\":null,\"tag\":null}' 'https://api.digitalocean.com/v2/domains/${var.domain}/records'",
            # "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ${var.do_token}' -d '{\"type\": \"CNAME\",\"name\": \"www.${var.github_repo}\",\"data\": \"${var.github_repo}.\",\"priority\":null,\"port\":null,\"ttl\":1800,\"weight\":null,\"flags\":null,\"tag\":null}' 'https://api.digitalocean.com/v2/domains/${var.domain}/records'",
            # "echo 'server { listen 80; server_name ${var.github_repo}.${var.domain} www.${var.github_repo}.${var.domain}; location / {proxy_pass http://${self.ipv4_address}:${var.puerto}/; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection 'upgrade'; proxy_set_header Host $host; proxy_cache_bypass $http_upgrade; proxy_set_header X-Real-IP $remote_addr;} }' > /etc/nginx/sites-available/${var.github_repo}.${var.domain}",
            # #"echo 'server { listen 80; server_name ${var.github_repo}.${var.domain} www.${var.github_repo}.${var.domain}; location / {proxy_pass http://${self.ipv4_address}:${var.puerto}/; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection 'upgrade'; proxy_set_header Host $host; proxy_cache_bypass $http_upgrade; proxy_set_header X-Real-IP $remote_addr;} }' > /etc/nginx/sites-available/${var.github_repo}.${var.domain}",
            # #"echo 'server { listen 80; location / { proxy_pass http://${self.ipv4_address}:${var.puerto}/; } }' > /etc/nginx/sites-available/default",
            # "sudo ln -s /etc/nginx/sites-available/${var.github_repo}.${var.domain} /etc/nginx/sites-enabled/",
            # "sudo sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/' /etc/nginx/nginx.conf",
            # "sudo bash -c 'cd /etc/nginx/sites-enabled; sudo unlink default'",
            # "sudo service nginx restart",
        ]
    }
}