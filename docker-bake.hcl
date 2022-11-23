variable "GITHUB_REF_NAME" {
  default = "dev"
}

variable "GITHUB_REPOSITORY" {
  default = "klutchell/dnscrypt-proxy-docker"
}

target "default" {
  context = "./"
  dockerfile = "Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm/v6",
    "linux/arm64"
  ]
  cache-from = [
    "ghcr.io/klutchell/dnscrypt-proxy:latest",
    "docker.io/klutchell/dnscrypt-proxy:latest",
    "ghcr.io/klutchell/dnscrypt-proxy:main",
    "docker.io/klutchell/dnscrypt-proxy:main",
    "type=registry,ref=ghcr.io/klutchell/dnscrypt-proxy:buildkit-cache-${regex_replace(GITHUB_REF_NAME, "[^[:alnum:]]", "-")},mode=max"
  ]
  cache-to = [
    "type=registry,ref=ghcr.io/klutchell/dnscrypt-proxy:buildkit-cache-${regex_replace(GITHUB_REF_NAME, "[^[:alnum:]]", "-")},mode=max"
  ]
}
