resource "aws_db_instance" "this" {
  count                = var.use_aurora ? 0 : 1
  identifier           = "rds-instance"
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = 20
  name                 = var.db_name
  username             = var.username
  password             = var.password
  multi_az             = var.multi_az
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
}
