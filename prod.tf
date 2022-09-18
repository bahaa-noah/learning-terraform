provider "aws" {
    profile = "terraform"
    region = "me-central-1"
}

resource "aws_s3_bucket" "prod_tf_course" {
    bucket = "test-tf-course-20220916"
    acl = "private"
}

resource "aws_default_vpc" "default" {
  
}