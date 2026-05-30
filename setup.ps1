mkdir sql
mkdir app-part1
mkdir app-part1\public
mkdir app-part1\src
mkdir app-part2
mkdir app-part2\src\main\java\com\libraryhub
mkdir app-part2\src\main\webapp\WEB-INF
mkdir terraform
mkdir terraform\modules
mkdir terraform\modules\vpc
mkdir terraform\modules\security_groups
mkdir terraform\modules\rds
mkdir terraform\modules\beanstalk
mkdir terraform\modules\alb
mkdir terraform\modules\ec2_asg
mkdir terraform\modules\route53
New-Item sql\schema.sql -ItemType File
New-Item app-part1\public\index.php -ItemType File
New-Item app-part1\public\health.php -ItemType File
New-Item app-part1\src\db.php -ItemType File
New-Item app-part2\pom.xml -ItemType File
New-Item app-part2\src\main\java\com\libraryhub\BookSearchServlet.java -ItemType File
New-Item app-part2\src\main\java\com\libraryhub\DB.java -ItemType File
New-Item app-part2\src\main\webapp\WEB-INF\search.jsp -ItemType File
New-Item app-part2\src\main\webapp\WEB-INF\web.xml -ItemType File
New-Item terraform\main.tf -ItemType File
New-Item terraform\variables.tf -ItemType File
New-Item terraform\outputs.tf -ItemType File
New-Item terraform\terraform.tfvars -ItemType File
New-Item terraform\modules\vpc\main.tf -ItemType File
New-Item terraform\modules\vpc\variables.tf -ItemType File
New-Item terraform\modules\vpc\outputs.tf -ItemType File
New-Item terraform\modules\security_groups\main.tf -ItemType File
New-Item terraform\modules\security_groups\variables.tf -ItemType File
New-Item terraform\modules\security_groups\outputs.tf -ItemType File
New-Item terraform\modules\rds\main.tf -ItemType File
New-Item terraform\modules\rds\variables.tf -ItemType File
New-Item terraform\modules\rds\outputs.tf -ItemType File
New-Item terraform\modules\beanstalk\main.tf -ItemType File
New-Item terraform\modules\beanstalk\variables.tf -ItemType File
New-Item terraform\modules\beanstalk\outputs.tf -ItemType File
New-Item terraform\modules\alb\main.tf -ItemType File
New-Item terraform\modules\alb\variables.tf -ItemType File
New-Item terraform\modules\alb\outputs.tf -ItemType File
New-Item terraform\modules\ec2_asg\main.tf -ItemType File
New-Item terraform\modules\ec2_asg\variables.tf -ItemType File
New-Item terraform\modules\ec2_asg\outputs.tf -ItemType File
New-Item terraform\modules\route53\main.tf -ItemType File
New-Item terraform\modules\route53\variables.tf -ItemType File
New-Item terraform\modules\route53\outputs.tf -ItemType File
New-Item README.md -ItemType File
Write-Host "Done! Files created:" (Get-ChildItem -Recurse -File).Count -ForegroundColor Green