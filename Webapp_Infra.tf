resource "aws_launch_template" "WebServerTemplate" {
    name = "WebServerTemplate"
    description = "EC2 Template for Web Servers"
    image_id = "ami-0c55b159cbfafe1f0" # replace with a valid AMI ID for your region
    instance_type = "t2.micro"
    key_name = "key_pem"
    security_group_ids = [aws_security_group.WebServerSG.id]
    user_data = <<-EOF
                apt update -y
                apt install apache2 -y
                cat <<EOF > 
                /var/www/html/index.html
                <!DOCTYPE html>
                <html lang="en">
                <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>My Simple Website</title>
                <style>
                  body {
                      font-family: Arial, sans-serif;
                      margin: 0;
                      padding: 0;
                    }
                  header {
                      background: #4CAF50;
                      color: white;
                      padding: 15px;
                      text-align: center;
                    }
                  nav {
                      background: #333;
                      padding: 10px;
                   }
                  nav a {
                      color: white;
                      margin: 0 10px;
                      text-decoration: none;
                 }
                </style>
                </head>
                <body>
                  <h1>Hello from ASG</h1>
                </body>
                </html>
                EOF
                systemctl start apache2
                systemctl enable apache2
              EOF
    tags = {
        Name = "WebServerTemplate" 
        }
}

resource "aws_autoscaling_group" "WebServerASG" {
    name = "WebServerASG"
    max_size = 6
    min_size = 1
    desired_capacity = 2
    launch_template {
        id = aws_launch_template.WebServerTemplate.id
        version = "$Latest"
    }
    availability_zones = ["us-east-1a", "us-east-1b"] # replace with valid AZs for your region
    vpc_zone_identifier = [aws_subnet.PrivateA.id, aws_subnet.PrivateB.id]
    tags = [
        {
            key = "Name"
            value = "WebServerASG"
            propagate_at_launch = true
        }
    ]
}

resource "aws_lb" "WebServerLB" {
    name = "WebServerLB"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.LB_SG.id]
    subnets = [aws_subnet.PublicA.id, aws_subnet.PublicB.id]
    tags = {
        Name = "WebServerLB"
    }
}

resource "aws_lb_target_group" "WebServerLB_TG" {
    name = "WebServerLB-TG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.VPC.id
    health_check {
        path = "/"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
        matcher = "200-299"
    }
    tags = {
        Name = "WebServerTG"
    }
}

resource "aws_target_group_attachment" "WebServerLB_TG_Attachment" {
    target_group_arn = [aws_lb_target_group.WebServerLB_TG.arn]
    target_id = aws_autoscaling_group.WebServerASG.id
    port = 80
}

resource "aws_lb_listener" "WebServerLB_Listener" {
    load_balancer_arn = aws_lb.WebServerLB.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.WebServerLB_TG.arn
    }
}

resource "aws_scaling_policy" "WebServerASG_ScaleOut" {
    name = "WebServerASG-ScaleOut"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.WebServerASG.name
    policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "WebServerASG_HighCPU" {
    alarm_name = "WebServerASG-HighCPU"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 1
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    dimension {
        name = "AutoScalingGroupName"
        value = aws_autoscaling_group.WebServerASG.name
    }
    period = 300
    statistic = "Average"
    threshold = 70
    alarm_actions = [aws_scaling_policy.WebServerASG_ScaleOut.arn]
}

resource "aws_scaling_policy" "WebServerASG_ScaleIn" {
    name = "WebServerASG-ScaleIn"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.WebServerASG.name
    policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "WebServerASG_LowCPU" {
    alarm_name = "WebServerASG-LowCPU"
    comparison_operator = "LessThanThreshold"
    evaluation_periods = 1
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    dimension {
        name = "AutoScalingGroupName"
        value = aws_autoscaling_group.WebServerASG.name
    }
    period = 300
    statistic = "Average"
    threshold = 20
    alarm_actions = [aws_scaling_policy.WebServerASG_ScaleIn.arn]
}

# Backup Webserver ASG
resource "aws_autoscaling_group" "Backup_WebServerASG" {
    name = "Backup-WebServerASG"
    max_size = 20
    min_size = 1
    desired_capacity = 4
    launch_template {
        id = aws_launch_template.WebServerTemplate.id
        version = "$Latest"
    }
    availability_zones = ["us-east-1a", "us-east-1b"] # replace with valid AZs for your region
    vpc_zone_identifier = [aws_subnet.PrivateA.id, aws_subnet.PrivateB.id]
    tags = [
        {
            key = "Name"
            value = "WebServerASG"
            propagate_at_launch = true
        }
    ]
}