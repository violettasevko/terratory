variable "AWS_Region" {
  description = "type a region (default - us-east-1)"
  type    = string
  default = "us-east-1"
}

variable "vpc_prefix" {
  description = "type a cidr (default - 10.40)"
  type    = string
  default = "10.40"
}

#sample
#terraform apply -var="AWS_Region=eu-central-1" -var="vpc_prefix=10.61"

provider "aws" {
    region = var.AWS_Region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Vpc4-vio"
  cidr = "${var.vpc_prefix}.0.0/16"

  azs             = ["${var.AWS_Region}a", "${var.AWS_Region}b", "${var.AWS_Region}c"]
   public_subnets  = ["${var.vpc_prefix}.11.0/24", "${var.vpc_prefix}.12.0/24", "${var.vpc_prefix}.13.0/24"]
   private_subnets = ["${var.vpc_prefix}.21.0/24", "${var.vpc_prefix}.22.0/24", "${var.vpc_prefix}.23.0/24"]
   intra_subnets = ["${var.vpc_prefix}.31.0/24", "${var.vpc_prefix}.32.0/24", "${var.vpc_prefix}.33.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  private_route_table_tags = {
    Name = "Vpc4-private-vio"
  }

  public_route_table_tags = {
    Name = "Vpc4-Public-vio"
  }
  
  intra_route_table_tags = {
    Name = "Vpc4-intra-vio"
  }
  
  enable_ipv6 = true
  assign_ipv6_address_on_creation = true

  public_subnet_ipv6_prefixes = [17, 18, 19]
  private_subnet_ipv6_prefixes = [33, 34, 35]
  intra_subnet_ipv6_prefixes = [49, 50, 51]

public_subnet_tags = {
  Name = "Vpc4 Public subnet vio"
}

private_subnet_tags = {
  Name = "Vpc4 private subnet vio"
}

intra_subnet_tags = {
  Name = "Vpc4 intra subnet vio"
}
}
  module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "web-sg-for-vpc4-vio"
  description = "web security group"
  vpc_id      = "module.vpc.vpc_id"

  ingress_cidr_blocks      = ["10.40.0.0/16"]
  ingress_rules            = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8090
      protocol    = "tcp"
      description = "web"
      cidr_blocks = "10.40.0.0/16"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.sg.vpc.id]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint-vio" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
     # policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
  }
    }
