provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "Production"
      Owner       = "mezebuiro@outlook.com"
      Project     = "ac-server"
    }
  }
}
