data "template_file" "admin_yml" {
  template = file("${path.module}/bootstrap/admin.yml")
}

data "template_file" "node_token_yml" {
  template = file("${path.module}/bootstrap/node_token.yml")
  vars = {
    node_token_address = local.node_token_address
  }
}

data "template_file" "bootstrap_sh" {
  template = file("${path.module}/bootstrap/bootstrap.sh")
  vars = {
    master_address     = local.master_address
    node_token_address = local.node_token_address
    admin_yml          = data.template_file.admin_yml.rendered
    node_token_yml     = data.template_file.node_token_yml.rendered
  }
}
