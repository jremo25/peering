terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Create VPCs
resource "aws_vpc" "vpc1" {
  cidr_block = "10.86.0.0/16"
  tags = {
    Name = "vpc1"
  }
}

resource "aws_vpc" "vpc2" {
  cidr_block = "10.70.0.0/16"
  tags = {
    Name = "vpc2"
  }
}

resource "aws_vpc" "vpc3" {
  cidr_block = "10.90.0.0/16"
  tags = {
    Name = "vpc3"
  }
}

# Create subnets for VPC1
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.86.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

# Create subnets for VPC2
resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "10.70.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

# Create subnets for VPC3
resource "aws_subnet" "public_subnet3" {
  vpc_id                  = aws_vpc.vpc3.id
  cidr_block              = "10.90.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

# Create Internet Gateways
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_internet_gateway" "igw2" {
  vpc_id = aws_vpc.vpc2.id
}

resource "aws_internet_gateway" "igw3" {
  vpc_id = aws_vpc.vpc3.id
}

# Create Route Tables and Associations
resource "aws_route_table" "rtb1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.rtb1.id
}

resource "aws_route_table" "rtb2" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw2.id
  }
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.rtb2.id
}

resource "aws_route_table" "rtb3" {
  vpc_id = aws_vpc.vpc3.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw3.id
  }
}

resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.public_subnet3.id
  route_table_id = aws_route_table.rtb3.id
}

# Create VPC peering connections
resource "aws_vpc_peering_connection" "vpc1_to_vpc2" {
  vpc_id      = aws_vpc.vpc1.id
  peer_vpc_id = aws_vpc.vpc2.id
  auto_accept = true
}

resource "aws_vpc_peering_connection" "vpc3_to_vpc1" {
  vpc_id      = aws_vpc.vpc3.id
  peer_vpc_id = aws_vpc.vpc1.id
  auto_accept = true
}

# Create routes for VPC1
resource "aws_route" "route_vpc1_to_vpc2" {
  route_table_id            = aws_route_table.rtb1.id
  destination_cidr_block    = aws_vpc.vpc2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
}

resource "aws_route" "route_vpc1_to_vpc3" {
  route_table_id            = aws_route_table.rtb1.id
  destination_cidr_block    = aws_vpc.vpc3.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc3_to_vpc1.id
}

# Create routes for VPC3 to VPC1
resource "aws_route" "route_vpc3_to_vpc1" {
  route_table_id            = aws_route_table.rtb3.id
  destination_cidr_block    = aws_vpc.vpc1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc3_to_vpc1.id
}

# Create routes for VPC2 to VPC1
resource "aws_route" "route_vpc2_to_vpc1" {
  route_table_id            = aws_route_table.rtb2.id
  destination_cidr_block    = aws_vpc.vpc1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
}

# Security groups for allowing traffic between VPCs 
resource "aws_security_group" "vpc1_sg" {
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc2.cidr_block, aws_vpc.vpc3.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc2_sg" {
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc1.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc3_sg" {
  vpc_id = aws_vpc.vpc3.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc1.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Assign security groups to instances using vpc_security_group_ids
resource "aws_instance" "instance1" {
  ami                    = "ami-01cd4de4363ab6ee8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.vpc1_sg.id]
}

resource "aws_instance" "instance2" {
  ami                    = "ami-01cd4de4363ab6ee8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet2.id
  vpc_security_group_ids = [aws_security_group.vpc2_sg.id]
}

resource "aws_instance" "instance3" {
  ami                    = "ami-01cd4de4363ab6ee8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet3.id
  vpc_security_group_ids = [aws_security_group.vpc3_sg.id]
}

# AWS Network Firewall - Stateless Rule Group
resource "aws_networkfirewall_rule_group" "stateless" {
  capacity = 100
  name     = "stateless-rule-group"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "10.86.0.0/16"
              }
              destination {
                address_definition = "10.70.0.0/16"
              }
              protocols = [6] 
            }
          }
          priority = 1
        }
        stateless_rule {
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "10.70.0.0/16"
              }
              destination {
                address_definition = "10.86.0.0/16"
              }
              protocols = [6] 
            }
          }
          priority = 2
        }
        stateless_rule {
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "10.90.0.0/16"
              }
              destination {
                address_definition = "10.86.0.0/16"
              }
              protocols = [6] 
            }
          }
          priority = 3
        }
      }
    }
  }
}

# AWS Network Firewall - Stateful Rule Group
resource "aws_networkfirewall_rule_group" "stateful" {
  capacity = 100
  name     = "stateful-rule-group"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST"]
        targets              = ["allowed.host.com"]
      }
    }
  }
}

# AWS Network Firewall - Firewall Policy
resource "aws_networkfirewall_firewall_policy" "policy1" {
  name = "policy1"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful.arn
    }
  }
}

# AWS Network Firewall - Firewall
resource "aws_networkfirewall_firewall" "firewall1" {
  name                = "firewall1"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy1.arn
  vpc_id              = aws_vpc.vpc1.id

  subnet_mapping {
    subnet_id = aws_subnet.public_subnet1.id
  }
}


