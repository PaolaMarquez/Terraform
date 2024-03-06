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
  # provisioner "remote-exec" {
  #   inline = [
  #     "export PATH=$PATH:/usr/bin",
  #     # install nginx
  #     "sudo apt-get update",
  #     "sudo apt-get -y install nginx",
  #     "sudo apt update && sudo apt upgrade -y",
  #     "adduser abrilpaola",
  #     "sudo usermod -aG sudo abrilpaola",
  #     "sudo apt update && sudo apt upgrade -y",
  #   ]
  # }

  #     provisioner "remote-exec" {
  #   inline = [
  #       "sudo adduser --disabled-password --gecos '' myuser",
  #       "sudo mkdir -p /home/myuser/.ssh",
  #       "sudo touch /home/myuser/.ssh/authorized_keys",
  #       "sudo echo '${var.pub_key}' > authorized_keys",
  #       "sudo mv authorized_keys /home/myuser/.ssh",
  #       "sudo chown -R myuser:myuser /home/myuser/.ssh",
  #       "sudo chmod 700 /home/myuser/.ssh",
  #       "sudo chmod 600 /home/myuser/.ssh/authorized_keys",
  #       "sudo usermod -aG sudo myuser",
  #       "sudo apt update && sudo apt upgrade -y",
  #       ""
  #  ]

    provisioner "remote-exec" {
    inline = [
            "sudo apt-get update",
            "sudo apt-get -y install nginx",  #instalar nginx
            "sudo adduser --disabled-password --gecos '' myuser",
            "sudo mkdir -p /home/myuser/.ssh",
            "sudo touch /home/myuser/.ssh/authorized_keys",
            "sudo echo '${var.pub_key}' > authorized_keys",
            "sudo mv authorized_keys /home/myuser/.ssh",
            "sudo chown -R myuser:myuser /home/myuser/.ssh",
            "sudo chmod 700 /home/myuser/.ssh",
            "sudo chmod 600 /home/myuser/.ssh/authorized_keys",
            "sudo usermod -aG sudo myuser",
            "sudo apt-get update",  #Antes estaba la de Quevedo
            "sudo -i -u myuser git clone ${var.github_link}",
            "sudo apt update", #instalar docker
            "sudo DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates curl software-properties-common", #saca cuadro morado
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
            "sudo add-apt-repository ${var.docker_link} -y",
            "sudo apt update",
            "apt-cache policy docker-ce",
            "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce", #saca cuadro morado
            "sudo curl -L ${var.docker_compose_link} -o /usr/local/bin/docker-compose",   #instalar docker compose
            "sudo chmod +x /usr/local/bin/docker-compose",
            "sudo usermod -aG docker myuser",
            "sudo -i -u myuser bash -c 'cd ${var.github_repo}; docker build .'",
            "sudo -i -u myuser bash -c 'cd ${var.github_repo}; docker run -it -d -p 8080:8080 $(docker images -q | head -n 1)'",
            # "docker run -it -d -p 8080:8080 $(docker images -q | head -n 1)",
            # "sudo su - myuser",
            # "su - myuser -c 'cd pinterest-clone && docker build -t my_image .'",
            # "su - myuser -c 'docker run -d -p 8080:80 my_image'",
        ]
        

    }
}