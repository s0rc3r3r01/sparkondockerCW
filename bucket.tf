provider "aws" {
    access_key = "${var.access}"
    secret_key = "${var.secret}"
    region = "us-east-1"
}

resource "aws_s3_bucket" "sparkresults" {
    bucket = "sparkresults"
    acl = "public-read-write"
    force_destroy = true
    policy = "${file("./resources/policy.json")}"

    tags {
        Name = "sparkresults bucket"
    }
}
