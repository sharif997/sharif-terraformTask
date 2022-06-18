resource "aws_db_subnet_group" "wordpress-subnetgroup" {
    name = "wordpress-subnetgroup"
    subnet_ids = [aws_subnet.databasesubnets.id]
    description = "This is subnet group for Database"
    tag = {
        Name = "Database-Subnet-group"
    }
}

#security Group for The RDS instance 
resource "aws_security_group" "custom-RDS-sg" {
    name = "custom-RDS-sg"
    vpc_id = aws_vpc.sharif.id
    description = "Security group for RDS Instances"
    
    #outgoing traffic
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
    #ingoing traffic
    ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      security_groups = [aws_security_group.custom-ec2-sg.id]
    }
    tag {
      name = "Custom RDS instance security Group "
    }
}

resource "aws_db_instance" "wordpressDB" {
    name = "wordpressDB"
    engine = "PostgreSQL"
    storage_type = "gp2"
    instance_class = "db.t3.micro"          #it is recommanded to change this to a higher tier for Production inv. 
    allocated_storage = 50
    max_allocated_storage = 100
    db_name = "wordpressDB"
    username = "admin"
    password = "P@sSwOrd1234"
    publicly_accessible = false
    port = 3306
    db_subnet_group_name = [aws_db_subnet_group.databasesubnets.name]
    vpc_security_group_ids = [aws_security_group.custom-RDS-sg.id]
    availability_zone = "us-east-1a"
}