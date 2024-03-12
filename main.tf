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
            "sudo apt-get update",
            "sudo ufw allow OpenSSH",
            "sudo ufw allow http",
            "sudo ufw allow https",
            "sudo ufw enable -y",
            "sudo adduser --disabled-password --gecos '' myuser",
            "sudo mkdir -p /home/myuser/.ssh",
            "sudo touch /home/myuser/.ssh/authorized_keys",
            "sudo echo '${var.pub_key}' > authorized_keys",
            "sudo mv authorized_keys /home/myuser/.ssh",
            "sudo chown -R myuser:myuser /home/myuser/.ssh",
            "sudo chmod 700 /home/myuser/.ssh",
            "sudo chmod 600 /home/myuser/.ssh/authorized_keys",
            "sudo usermod -aG sudo myuser",
            "${var.command} apt-get -y install nginx",  #instalar nginx
            "sudo apt-get update",  #Antes estaba la de Quevedo
            "${var.command} git clone ${var.github_link}",
            "sudo apt update", #instalar docker
            "${var.command} DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates curl software-properties-common", #saca cuadro morado
            "${var.command} curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${var.command} apt-key add -", #este no tenía sudo
            "${var.command} add-apt-repository ${var.docker_link} -y",
            "${var.command} apt update",
            "apt-cache policy docker-ce",
            "${var.command} DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce", #saca cuadro morado
            "${var.command} curl -L ${var.docker_compose_link} -o /usr/local/bin/docker-compose",   #instalar docker compose
            "${var.command} chmod +x /usr/local/bin/docker-compose",
            "${var.command} usermod -aG docker myuser",
            "${var.command} bash -c 'cd ${var.github_repo}; docker build .'",
            "${var.command} bash -c 'cd ${var.github_repo}; docker run -it -d -p ${var.puerto}:${var.puerto} $(docker images -q | head -n 1)'",
            "echo 'server { listen 80; location / { proxy_pass http://${self.ipv4_address}:${var.puerto}/; } }' > /etc/nginx/sites-available/default",
            "service nginx restart",
        ]
    }
}