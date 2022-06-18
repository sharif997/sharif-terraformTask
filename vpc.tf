#Create the VPC
 resource "aws_vpc" "sharif" {
   cidr_block       = var.sharif_vpc_cidr               # Defining the CIDR block use 192.168.0.0/16 
   instance_tenancy = "default"
 }

 #Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "sharif-IGW" {
  vpc_id =  aws_vpc.sharif.id
 }

 #Create a Public Subnets   "us-east-1a"
 resource "aws_subnet" "publicsubnets" { 
  vpc_id =  aws_vpc.sharif.id
  cidr_block = "${var.public_subnets}"              # CIDR block of public subnets 192.168.0.0/24
  availability_zone = "us-east-1a"
 }

 #Create a Private Subnet in     "us-east-1a"
 resource "aws_subnet" "AZ-1a-private_subnets" {
  vpc_id =  aws_vpc.sharif.id
  cidr_block = "${var.AZ-1a-private_subnets}"               # CIDR block of private subnets 192.168.1.0/24
  availability_zone = "us-east-1a"

 }

#Create a Private Subnet in     "us-east-1b"
 resource "aws_subnet" "AZ-1b-private_subnets" {
  vpc_id =  aws_vpc.sharif.id
  cidr_block = "${var.AZ-1b-private_subnets}"               # CIDR block of private subnets 192.168.2.0/24
  availability_zone = "us-east-1b"

 }
 #Create a database  Subnet  
 resource "aws_subnet" "databasesubnets" {
   vpc_id =  aws_vpc.sharif.id
   cidr_block = "${var.database_subnets}"                # CIDR block of database subnets 192.168.2.0/24
   availability_zone = "us-east-1a"
 }

 #Route table for Public Subnet's
 resource "aws_route_table" "PublicRT" {
    vpc_id =  aws_vpc.sharif.id
         route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sharif-IGW.id
     }
 }

 #Route table for Private Subnet in AZ us-east-1a
 resource "aws_route_table" "AZ-1a-PrivateRT" {                
   vpc_id = aws_vpc.sharif.id
   route {
   cidr_block = "0.0.0.0/0"                                 
   nat_gateway_id = aws_nat_gateway.sharif-NATgw.id
   }
 }

 #Route table for Private Subnet in AZ us-east-1b
 resource "aws_route_table" "AZ-1b-PrivateRT" {                
   vpc_id = aws_vpc.sharif.id
   route {
   cidr_block = "0.0.0.0/0"                                 
   nat_gateway_id = aws_nat_gateway.sharif-NATgw.id
   }
 }

#Route table for database Subnet's
 resource "aws_route_table" "DatabaseRT" {
   vpc_id = aws_vpc.sharif.id
   route {
   cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.sharif-NATgw.id
   }
 }

 #Route table Association with Public Subnet in AZ us-east-1a
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }

 #Route table Association with Private AZ us-east-1a
 resource "aws_route_table_association" "AZ-1a-PrivateRTassociation" {
    subnet_id = aws_subnet.AZ-1a-private_subnets.id
    route_table_id = aws_route_table.AZ-1a-PrivateRT.id
 }

  #Route table Association with Private in AZ us-east-1b
 resource "aws_route_table_association" "AZ-1b-PrivateRTassociation" {
    subnet_id = aws_subnet.AZ-1b-private_subnets.id
    route_table_id = aws_route_table.AZ-1b-PrivateRT.id
 }

 #Route table Association with databse Subnet's
 resource "aws_route_table_association" "DatabaseRTassociation" {
    subnet_id = aws_subnet.databasesubnets.id
    route_table_id = aws_route_table.DatabaseRT.id
 }

 resource "aws_eip" "nateIP" {
   vpc   = true
 }

 #Creating the NAT Gateway using subnet_id and allocation_id
 resource "aws_nat_gateway" "sharif-NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets.id
 }