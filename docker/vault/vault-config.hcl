#cat /var/services/vault/config/vault-config.hcl


disable_cache       = true
disable_mlock       = true
ui                  = true
max_lease_ttl       = "2h"
default_lease_ttl   = "20m"
raw_storage_endpoint = "true"
disable_printable_check = "true"
cluster_addr        = "https://localhost:8201"
api_addr            = "https://localhost

listener "tcp" {
  address                   = "0.0.0.0:8200"
  tls_disable               = false
  tls_client_ca_file        = "/certs/myCA.crt"
  tls_cert_file             = "/certs/localhost.crt"
  tls_key_file              = "/certs/localhost.key"
  tls_disable_client_certs  = "true"
}

storage "raft" {
  node_id  = "vault-1"
  path     = "/vault/data"
}
