resource "null_resource" "install_master" {
  depends_on = [aws_instance.k3s_master]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.k3s_master.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -",
      "sleep 10",
      "sudo chmod 644 /etc/rancher/k3s/k3s.yaml"
    ]
  }
}

resource "null_resource" "get_credentials" {
  depends_on = [null_resource.install_master]

  provisioner "local-exec" {
    command = <<EOT
      scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@${aws_instance.k3s_master.public_ip}:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml
      sed -i 's/127.0.0.1/${aws_instance.k3s_master.public_ip}/g' ./kubeconfig.yaml
      ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@${aws_instance.k3s_master.public_ip} "sudo cat /var/lib/rancher/k3s/server/node-token" > ./node-token
    EOT
  }
}

data "local_file" "k3s_token" {
  depends_on = [null_resource.get_credentials]
  filename   = "./node-token"
}

resource "null_resource" "install_workers" {
  count      = 2
  depends_on = [data.local_file.k3s_token]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.k3s_worker[count.index].private_ip
    
    bastion_host        = aws_instance.k3s_master.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443 K3S_TOKEN=${trimspace(data.local_file.k3s_token.content)} sh -"
    ]
  }
}