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
          "adduser myuser --disabled-password --gecos ''",
          "echo 'myuser: ${var.pwd}' | chpasswd",
          "sudo mkdir -p /home/myuser/.ssh",
          "sudo touch /home/myuser/.ssh/authorized_keys",
          "sudo echo '${var.pub_key}' > authorized_keys",
          "sudo mv authorized_keys /home/myuser/.ssh",
          "sudo chown -R myuser:myuser /home/myuser/.ssh",
          "sudo chmod 700 /home/myuser/.ssh",
          "sudo chmod 600 /home/myuser/.ssh/authorized_keys",
          "sudo usermod -aG sudo myuser",
          "echo 'myuser ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/myuser",
      ]
  }
}

resource "null_resource" "change_user" {
  depends_on = [digitalocean_droplet.web]
  connection {
    host = digitalocean_droplet.web.ipv4_address
    user = "myuser"
    password = var.pwd
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

  provisioner "remote-exec" {
  inline = [
          #Git
          "git clone ${var.github_link}",

          #Docker
          "sudo apt update",
          "sudo DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates curl software-properties-common",
          "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
          "echo ${var.docker_link} | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
          "sudo apt update",
          "sudo DEBIAN_FRONTEND=noninteractive apt install -y docker-ce",
          "sudo usermod -aG docker myuser",

          #Docker Compose
          "mkdir -p ~/.docker/cli-plugins/ && curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose",  #REVISAR
          "chmod +x ~/.docker/cli-plugins/docker-compose",
          "sudo bash -c 'cd ${var.github_repo}; docker compose up -d'",

          #Domain
          "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ${var.do_token}' -d '{\"type\":\"A\",\"name\":\"${var.github_repo}\",\"data\":\"${digitalocean_droplet.web.ipv4_address}\",\"priority\":null,\"port\":null,\"ttl\":3600,\"weight\":null,\"flags\":null,\"tag\":null}' 'https://api.digitalocean.com/v2/domains/${var.domain}/records'",
          "curl -X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer ${var.do_token}' -d '{\"type\": \"CNAME\",\"name\": \"www.${var.github_repo}\",\"data\": \"${var.github_repo}.\",\"priority\":null,\"port\":null,\"ttl\":1800,\"weight\":null,\"flags\":null,\"tag\":null}' 'https://api.digitalocean.com/v2/domains/${var.domain}/records'",
          
          #Nginx
          "sudo apt update",
          "sudo DEBIAN_FRONTEND=noninteractive apt install -y nginx",
          "sudo ufw app list",
          "sudo ufw allow 'Nginx Full'",

          #Nginx Config
          "sudo touch /etc/nginx/sites-available/exercisediary.deploy-tap.site",
          "sudo echo 'server { listen 80; server_name ${var.github_repo}.${var.domain} www.${var.github_repo}.${var.domain}; location / {proxy_pass http://${digitalocean_droplet.web.ipv4_address}:${var.puerto}/; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection 'upgrade'; proxy_set_header Host $host; proxy_cache_bypass $http_upgrade; proxy_set_header X-Real-IP $remote_addr;} }' | sudo tee -a /etc/nginx/sites-available/${var.github_repo}.${var.domain}",
          "sudo sed -i 's/# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/' /etc/nginx/nginx.conf",
          "sudo ln -s /etc/nginx/sites-available/${var.github_repo}.${var.domain} /etc/nginx/sites-enabled/",
          "sudo bash -c 'cd /etc/nginx/sites-enabled; sudo unlink default'",
          "sudo systemctl restart nginx",

          #SSL certificate
          # "sudo add-apt-repository ppa:certbot/certbot",
          "sudo apt-get update",
          "sudo DEBIAN_FRONTEND=noninteractive apt-get install certbot python3-certbot-nginx -y",
          # "sleep 1m",
          "sudo certbot --nginx -n -d ${var.github_repo}.${var.domain} -d www.${var.github_repo}.${var.domain} --agree-tos -m ${var.email} --no-eff-email --redirect",            
          "sudo certbot renew --dry-run",
          # "sudo service nginx restart",
      ]
  }
}