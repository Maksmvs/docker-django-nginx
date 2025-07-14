resource "aws_rds_cluster" "this" {
  count               = var.use_aurora ? 1 : 0
  cluster_identifier  = "aurora-cluster"
  engine              = var.engine
  engine_version      = var.engine_version
  master_username     = var.username
  master_password     = var.password
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

resource "aws_rds_cluster_instance" "writer" {
  count               = var.use_aurora ? 1 : 0
  identifier          = "aurora-instance-1"
  cluster_identifier  = aws_rds_cluster.this[0].id
  instance_class      = var.instance_class
  engine              = var.engine
  engine_version      = var.engine_version
  publicly_accessible = false
}
