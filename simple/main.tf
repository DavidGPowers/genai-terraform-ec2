module "web_server" {
  source = "./modules/ec2-instance"  # path to your module

  name               = "my-ec2-instance"
  ami                = "ami-02b297871a94f4b42"
  instance_type      = "t3.micro"
  subnet_id          = "subnet-c72681af"
  security_group_ids = ["sg-8809d8ec"]
  key_name           = "labkey"

  tags = {
    Environment = "dev"
    Owner       = "me"
  }
}
