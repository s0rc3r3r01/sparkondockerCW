# Configure the Azure Provider
provider "azure" {
    publish_settings = "${file("freetrial.publishsettings")}"
}


resource "azure_hosted_service" "default-service" {
    name = "default-service-spark-cloud-computing-city"
    location = "East US"
    ephemeral_contents = false
    description = "Made for Cloud Computing project."
    label = "df-hs-01"
    depends_on = ["aws_s3_bucket.sparkresults"]
}
#note MUST BE UNIQUE in Azure namespace
resource "azure_storage_service" "tfstor" {
    name = "cloudcompcity86"
    location = "East US"
    description = "Made for Cloud Computing project."
    account_type = "Standard_LRS"
}

resource "azure_instance" "master" {
    name = "master"
    hosted_service_name = "${azure_hosted_service.default-service.name}"
    image = "Ubuntu Server 14.04 LTS"
    size = "A10"
    storage_service_name = "${azure_storage_service.tfstor.name}"
    location = "East US"
    username = "ubuntu"
    password = "Pass!admin123"

    endpoint {
        name = "SSH"
        protocol = "tcp"
        public_port = 22
        private_port = 22
    }
    endpoint {
        name = "Spark"
        protocol = "tcp"
        public_port = 8042
        private_port = 8042
    }

        endpoint {
        name = "sparkUI"
        protocol = "tcp"
        public_port = 8080
        private_port = 8080
    }

        endpoint {
        name = "workerUI"
        protocol = "tcp"
        public_port = 8081
        private_port = 8081
    }

        endpoint {
        name = "Spark_control"
        protocol = "tcp"
        public_port = 8088
        private_port = 8088
    }


        endpoint {
        name = "spark_management"
        protocol = "tcp"
        public_port = 4040
        private_port = 4040
    }



###provisioners section

   provisioner "file" {
    source = "resources/"
    destination = "/tmp/"
      connection {
          type = "ssh"
          user = "ubuntu"
          password = "Pass!admin123"


    }

}

        provisioner "remote-exec" {
        script = "./resources/docker.sh"
        connection {
            type = "ssh"
            user = "ubuntu"
            password = "Pass!admin123"

    }
        }

}
#output section

    output "address" {
    value = "${azure_instance.master.vip_address}"
}


    output "id" {
    value = "${azure_instance.master.id}"
}
