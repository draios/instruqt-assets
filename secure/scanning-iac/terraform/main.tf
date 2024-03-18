resource "aws_s3_bucket" "example_bucket" {
    bucket = "example-bucket"
    acl    = "public-read"

    website {
        index_document = "index.html"
        error_document = "error.html"
    }
}