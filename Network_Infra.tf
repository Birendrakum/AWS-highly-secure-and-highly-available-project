resource "aws_vpc" "VPC" {
    cidr_block = "192.168.10.0/24"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "Website-VPC"
}
}

resource "aws_subnet" "PublicA" {
    vpc_id = aws_vpc.VPC.id
    cidr_block = "192.168.10.0/26"
    availability_zone = "us-east-1a"
    tags = {
        Name = "Public-Subnet-A"
    }
}

resource "aws_subnet" "PublicB" {
    vpc_id = aws_vpc.VPC.id
    cidr_block = "192.168.10.64/26"
    availability_zone = "us-east-1b"
    tags = {
        Name = "Public-Subnet-B"
    }
}

resource "aws_subnet" "PrivateA" {
    vpc_id = aws_vpc.VPC.id
    cidr_block = "192.168.10.128/26"
    availability_zone = "us-east-1a"
    tags = {
        Name = "Private-Subnet-A"
    }
}

resource "aws_subnet" "PrivateB" {
    vpc_id = aws_vpc.VPC.id
    cidr_block = "192.168.10.192/26"
    availability_zone = "us-east-1b"
    tags = {
        Name = "Private-Subnet-B"
    }   
}

resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.VPC.id
    tags = {
        Name = "Main-Internet-Gateway"
    }
}

resource "aws_eip" "NAT" {
    vpc = true
    tags = {
        Name = "NAT-EIP"
    }
}

resource "aws_nat_gateway" "NATGW" {
    allocation_id = aws_eip.NAT.id
    subnet_id = aws_subnet.PublicA.id
    tags = {
        Name = "Main-NAT-Gateway"
    }
}

resource "aws_route_table" "PrivateRT" {
    vpc_id = aws_vpc.VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.NATGW.id
    }
}
resource "aws_route_table" "PublicRT" {
    vpc_id = aws_vpc.VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW.id
    }
}

resource "aws_route_table_association" "PublicA" {
    subnet_id = aws_subnet.PublicA.id
    route_table_id = aws_route_table.PublicRT.id
}

resource "aws_route_table_association" "PublicB" {
    subnet_id = aws_subnet.PublicB.id
    route_table_id = aws_route_table.PublicRT.id
}

resource "aws_route_table_association" "PrivateA" {
    subnet_id = aws_subnet.PrivateA.id
    route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_route_table_association" "PrivateB" {
    subnet_id = aws_subnet.PrivateB.id
    route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_security_group" "WebServerSG" {
    name = "WebServerSG"
    description = "Security group for web servers"
    vpc_id = aws_vpc.VPC.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.LB-SG.id]
    }
}

resource "aws_security_group" "LB-SG" {
    name = "LoadBalancerSG"
    description = "Security group for Load Balancer"
    vpc_id = aws_vpc.VPC.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "Isolated-SG" {
    name = "IsolatedSG"
    description = "Security group for isolated instances"
    vpc_id = aws_vpc.VPC.id
}
