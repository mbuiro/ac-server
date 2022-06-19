resource "aws_ecr_repository" "ac_ecr_repo" {
  name                 = "assetto-corsa"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

