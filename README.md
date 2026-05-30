# Project 5 – LibraryHub

## Traffic Flows

```
PART 1
──────
User → Route 53
       → Beanstalk URL (CNAME)
         → EB-managed ALB  (public subnets, AZ-1a + AZ-1b)
           → EB ASG  (PHP 8.4 / Nginx, private subnets)
             → RDS MySQL (private DB subnets, Multi-AZ)

PART 2
──────
User → Route 53
       → EC2 ALB  (public subnets, AZ-1a + AZ-1b)
         → EC2 ASG  (Java 21 / Tomcat 10, private subnets)
           → RDS MySQL (same shared database)
```

## Apps

| Part | Stack | What it does |
|------|-------|-------------|
| 1 | PHP 8.4 + Beanstalk | Registration form → saves library name, phone, email to RDS |
| 2 | Java 21 + Tomcat + EC2 | Search box → queries `books` table → shows Available / Not Available |

## File Structure

```
project5-final/
├── sql/schema.sql                    ← Run once on RDS
│
├── terraform/
│   ├── main.tf                       ← Wires all modules
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars              ← Edit db_password before deploy
│   └── modules/
│       ├── vpc/                      ← Multi-AZ VPC (public/app/db tiers)
│       ├── security_groups/          ← ALB, EC2, Beanstalk, RDS SGs
│       ├── rds/                      ← MySQL 8.0 Multi-AZ
│       ├── alb/                      ← EC2 ALB for Part 2
│       ├── beanstalk/                ← PHP 8.4 EB app + env (Part 1)
│       ├── ec2_asg/                  ← Java/Tomcat ASG + scaling (Part 2)
│       └── route53/                  ← Health checks + alias records
│
├── app-part1/                        ← PHP app (deploy as ZIP to EB)
│   ├── public/index.php
│   ├── public/health.php
│   └── src/db.php
│
└── app-part2/                        ← Java app (mvn package → WAR)
    ├── pom.xml
    └── src/main/
        ├── java/com/libraryhub/
        │   ├── BookSearchServlet.java
        │   └── DB.java
        └── webapp/WEB-INF/
            ├── search.jsp
            └── web.xml
```

## Deploy Steps

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform apply -var="db_password=YourPassword123!"

# 2. Get RDS endpoint and run schema
RDS=$(terraform output -raw rds_endpoint)
mysql -h $RDS -u admin -p < ../sql/schema.sql

# 3. Deploy Part 1 (PHP → Beanstalk)
cd ../app-part1
zip -r ../../part1.zip public/ src/
# Upload part1.zip via EB Console → Upload and Deploy

# 4. Deploy Part 2 (Java → Tomcat)
cd ../app-part2
mvn clean package
# Copy target/libraryhub.war to /opt/tomcat/webapps/ on EC2
# OR use CodeDeploy (see terraform/modules/ec2_asg for CodeDeploy setup)

# 5. Check outputs
cd ../terraform && terraform output
# part1_beanstalk_url = http://libraryhub-prod-php-env.xxx.elasticbeanstalk.com
# part2_ec2_alb_url   = http://libraryhub-prod-ec2-alb-xxx.us-east-1.elb.amazonaws.com/libraryhub/search
# rds_endpoint        = libraryhub-prod-mysql.xxx.us-east-1.rds.amazonaws.com
```
