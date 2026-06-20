resource "aws_key_pair" "k3s_key" {
  key_name   = "k3s-global-key"
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}