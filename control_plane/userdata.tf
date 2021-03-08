# ####################################################################################################
# # Config Files
# ####################################################################################################
# data "template_file" "admin_yaml" {
#   template = file("${path.module}/user_data/admin.yaml")
# }

# data "template_file" "worker_bootstrapper_yaml" {
#   template = file("${path.module}/user_data/worker-bootstrapper.yaml")
# }

# data "template_file" "graceful_shutdown_service" {
#   template = file("${path.module}/user_data/graceful-shutdown.service")
#   vars     = {
#     kubernetes_unit = "k3s"
#   }
# }

# data "template_file" "graceful_shutdown_sh" {
#   template = file("${path.module}/user_data/graceful-shutdown.sh")
#   vars     = {
#     control_plane_address = "localhost"
#   }
# }

# ####################################################################################################
# # Bootstrapping Script
# ####################################################################################################
# data "template_file" "bootstrap_sh" {
#   template = file("${path.module}/user_data/bootstrap.sh")
#   vars = {
#     k3s_install_options       = local.k3s_install_options
#     k3s_options               = base64encode(local.k3s_options)
#     control_plane_sans        = base64encode( join(", ", local.control_plane_sans) )
#     admin_yaml                = base64encode(data.template_file.admin_yaml.rendered)
#     worker_bootstrapper_yaml  = base64encode(data.template_file.worker_bootstrapper_yaml.rendered)
#     graceful_shutdown_service = base64encode(data.template_file.graceful_shutdown_service.rendered)
#     graceful_shutdown_sh      = base64encode(data.template_file.graceful_shutdown_sh.rendered)
#   }
# }
