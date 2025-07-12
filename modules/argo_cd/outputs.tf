output "argo_cd_url" {
  value = helm_release.argo_cd.status[0].load_balancer[0].hostname
}
