resource "aws_instance" "My_instance" {
    ami = "ami-0a91cd140a1fc148a"
    instance_type = "t2.micro"
    security_groups = ["default"]
    key_name = "nikhil-ec2"
    tags = {
        Name = "Nikhil-VM"
    }
}
