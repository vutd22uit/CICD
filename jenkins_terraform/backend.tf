terraform {
  backend "s3" {
    bucket = "tertris-bucket" 
    key    = "Jenkins/terraform.tfstate"
    region = "us-east-1"
  }
}
