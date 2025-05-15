terraform {
    backend "s3" {
        bucket = "dev-applications-backend-state-123"
        #key = "07-backend-state-users-dev"
        key = "dev/backend-state/users/backend-state"
        region = "us-east-1"
        dynamodb_table = "dev_application_locks"
        encrypt = true
    }
}



provider "aws" {
    

}

resource "aws_vpc" "myVPC" {
    cidr_block = "10.0.0.0/16"
  
}

resource "aws_subnet" "public_subnet_a" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
  
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"

}

resource "aws_subnet" "private_subnet_a" {
  vpc_id = aws_vpc.myVPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  
}
resource "aws_subnet" "private_subnet_b" {
  vpc_id = aws_vpc.myVPC.id
  cidr_block = "10.0.4.0/24"
  availabilyyity_zone = "us-east-1b"
  
}

resource "aws_internet_gateway" "myVPC" {
    vpc_id = aws_vpc.myVPC.id


}   

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.myVPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myVPC.id
    }

}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_app_secgrp" {
  vpc_id = aws_vpc.myVPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dbsecgrp" {
  vpc_id = aws_vpc.myVPC.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24","10.0.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_app_secgrp.id]
  subnets            = [aws_subnet.public_subnet_b.id,aws_subnet.public_subnet_a.id]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myVPC.id

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "random_string" "web_suffix" {
  length  = 8
  special = false
}

resource "random_string" "app_suffix" {
  length  = 8
  special = false
}

resource "aws_launch_configuration" "web_1c" {
  name          = "web_lc-${random_string.web_suffix.result}"
  image_id      = data.aws_ami.myami.id
  key_name      = "26april2024"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_app_secgrp.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "hii this is web server" > /var/www/html/index.html
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "echo Launch Configuration created!"
  }
}




resource "aws_launch_configuration" "app_1c" {
  name          = "app_lc-${random_string.app_suffix.result}"
  image_id      = data.aws_ami.myami.id
  key_name      = "26april2024"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_app_secgrp.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "hii this is app server" > /var/www/html/index.html
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "echo Launch Configuration created!"
  }
}
  


resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_1c.id
  vpc_zone_identifier  = [aws_subnet.public_subnet_a.id]
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1

  target_group_arns = [aws_lb_target_group.web_tg.arn]
  
}

resource "aws_autoscaling_group" "app_asg" {
  launch_configuration = aws_launch_configuration.app_1c.id
  vpc_zone_identifier = [aws_subnet.public_subnet_b.id]
  min_size = 1 
  max_size = 3
  desired_capacity   = 1

  target_group_arns = [aws_lb_target_group.web_tg.arn]

}

resource "aws_db_instance" "db_server" {
  identifier = "mydb-instance"
  allocated_storage = 10
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  username = "admin"
  password = "passward"
  db_subnet_group_name = aws_db_subnet_group.mydb.name
  vpc_security_group_ids = [aws_security_group.dbsecgrp.id]

  skip_final_snapshot = true

}

resource "aws_db_subnet_group" "mydb" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id,aws_subnet.private_subnet_b.id]
}

resource "aws_route53_zone" "myVPC" {
  name = "example-1.com"

  

}


resource "aws_route53_record" "web_record" {
  zone_id = aws_route53_zone.myVPC.zone_id
  name    = "web.example-1.com"
  type    = "A"
  ttl =  300
  
   records = ["192.0.3.44"]

  
  multivalue_answer_routing_policy = true
  set_identifier = "web-record"
  
  
}

resource "aws_route53_record" "app_record" {
  zone_id = aws_route53_zone.myVPC.zone_id
  name    = "app.example-1.com"
  type    = "A"
  ttl = 300
  
   records = ["192.0.2.44"]

  
  multivalue_answer_routing_policy = true
  set_identifier = "app-record"
  
}
