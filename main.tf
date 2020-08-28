variable "stack_name" {
  type = string
  description = "any string that arbitrarily denotes a given stack"
  default = "arbitrary-value"
}

locals {
  stack_name_hash = sha512(var.stack_name)
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc_${local.stack_name_hash}"
  }
}

# This resource does not require replacement
resource "aws_security_group" "my_security_group_1" {
  name = substr("my-security-group1_${var.stack_name}", 0, 255)
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = substr("my-security-group1_${var.stack_name}", 0, 255)
  }
}

# This resource requires replacement
resource "aws_security_group" "my_security_group_2" {
  name = substr("my-security-group2_${local.stack_name_hash}", 0, 255)
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = substr("my-security-group2_${local.stack_name_hash}", 0, 255)
  }
}

# Specifying the name_prefix at its max length circumvents this weirdness
resource "aws_security_group" "my_security_group_3" {
  name_prefix = substr("my-security-group3_${local.stack_name_hash}", 0, 100)
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = substr("my-security-group3_${local.stack_name_hash}", 0, 134)
  }
}

# Specifying a name <= 26 characters does not require replacement
resource "aws_security_group" "my_security_group_4" {
  name = "aaaaaaaaaaaaaaaaaaaaaaaaaa"
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-security-group4_ax26"
  }
}

# Specifying a name > 26 characters requires replacement
resource "aws_security_group" "my_security_group_5" {
  name = "aaaaaaaaaaaaaaaaaaaaaaaaaaa"
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-security-group5_ax27"
  }
}

# Specifying six groups of five chars delimited by '-' requires no replacement (35 chars)
resource "aws_security_group" "my_security_group_6" {
  name = "aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa"
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-security-group6_a-a-a-a-a-a"
  }
}

# Knowing that grouping these by a non-alphanumeric prevents this behavior we can use this
# knowledge to crate a workaround

locals {
  workaround_name = join("-", [for item in chunklist(split("", sha512(var.stack_name)), 16): join("", item) ])
}

resource "aws_security_group" "my_security_group_7" {
  name = local.workaround_name
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-security-group7_workaround"
  }
}
