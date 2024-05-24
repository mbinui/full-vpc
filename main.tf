# create vpc
resource "aws_vpc" "main"{
    cidr_block = var.vpc_cidr

tags = {
    Name = "my_vpc"
}
}

# create IGW
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.main.vpc_id

tags = {
    Name = "igw"
}
}

# create EIP
resource "aws_eip" "nat"{

tags = {
    Name = "nat"
}
}

# create NAT gateway
resource "aws_nat_gateway" "nat"{
    allocation_id = aws_eip.nat.vpc_id
    subnet_id     = aws_subnet.public[0].id

tags = {
    Name = "nat"
}
depends_on = [aws_internet_gateway.igw]
}

# create private subnet
resource "aws_subnet" "private"{
count             = length(slice(var.private_cidr, 0, var.private_subnet_count))
vpc_id            = aws_vpc.main.id
cidr_block        = element(slice(var.private_cidr, 0, var.private_subnet_count), count.index)
availability_zone = element(var.availability_zones, count.index)

tags = {
    Name = "private"
}
}

# create public subnet
resource "aws_subnet" "public"{
count                   = length(slice(var.public_cidr, 0, var.plubic_subnet_count))
vpc_id                  = aws_vpc.main.id
cidr_block              = element(slice(var.public_cidr, 0, var.public_subnet_count), count.index)
availability_zone       = element(var.availability_zones, count.index)
map_public_ip_on_launch = true 

tags = {
    Name = public
}
}

# create private route table
resource "aws_route_table" "private"{
    vpc_id = aws_vpc.main.id

    depends_on = [aws_subnet.private]

tags = {
    Name = "private"
}
}

# create public route table
resource "aws_route_table" "public"{
    vpc_id = aws_vpc.main.id

    depends_on = [aws_subnet.public]

tags = {
    Name = "public"
}
}

# create public routes
resource "aws_route" "public_internet_gateway"{
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id

    depends_on = [aws_route_table.public]
}

# private routes
resource "aws_route" "private_nat_gateway"{
    route_table_id = aws_route_table.private.id
    nat_gateway_id = aws_nat_gateway.nat.id
    destination_cidr_block = "0.0.0.0/0"

    depends_on = [aws_route_table.private]
}

# private route association
resource "aws_route_table_association" "private"{
count = length(slice(var.private_cidr, 0, var.private_subnet_count))

subnet_id      = element(aws.subnet.private[*].id, count.index)
route_table_id = aws_route_table.private.id

depends_on = [aws_route.private_nat_gateway, aws_subnet.private]
}

# private route association
resource "aws_route_table_association" "public"{
count = length(slice(var.public_cidr, 0, var.public_subnet_count))

subnet_id      = element(aws.subnet.public[*].id, count.index)
route_table_id = aws_route_table.public.id

depends_on = [aws_route.public_internet_gateway, aws_subnet.public]
}

resource "aws_security_group" "elk_sg"{
}

resource "terraform_remote_state" "network"{
}