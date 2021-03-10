locals {
  region     = data.aws_region.current.name
  vpc_id     = (var.vpc_id == null ? data.aws_vpc.main[0].id : var.vpc_id)
  subnet_ids = sort(var.subnet_ids == null ? data.aws_subnet_ids.main[0].ids : var.subnet_ids)
}
