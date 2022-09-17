provider "aws" {
    profile = "default"
    region = "me-central-1"
}

resource "aws_s3_bucket" "tf_course" {
    bucket = "tf-course-20220916"
    acl = "private"
}