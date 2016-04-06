
resource "aws_security_group" "sec_group" {
  name = "allow_ssh_spark_workers"
  description = "Allow SSH and Spark inbound traffic"
  depends_on = ["aws_s3_bucket.sparkresults"]
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  /* exposing ports for apache spark remote control
  */

   ingress {
      from_port = 8080
      to_port = 8088
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

     ingress {
      from_port = 8042
      to_port = 8042
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
      from_port = 4040
      to_port = 4040
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "allow_ssh_spark_workers"
  }
}


resource "aws_instance" "master" {
    ami = "ami-fce3c696"
    instance_type = "i2.xlarge"
    #make sure to have this public key stored in ec2
    key_name = "us1"
    security_groups = [ "${aws_security_group.sec_group.name}" ]

    provisioner "file" {
     source = "resources/"
     destination = "/tmp/"
     connection {
         type = "ssh"
         user = "ubuntu"
         private_key = "${file("./resources/us1.pem")}"

 }
     }


    provisioner "remote-exec" {
        script = "./resources/docker.sh"
        connection {
            type = "ssh"
            user = "ubuntu"
            private_key = "${file("./resources/us1.pem")}"

    }

    }



}
    #output section

  output "address" {
    value = "${aws_instance.master.public_dns}"
}
