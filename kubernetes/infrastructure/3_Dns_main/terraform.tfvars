# =============================================================================
# General Configuration
# =============================================================================
aws_region   = "us-east-2"
project_name = "test-majd-llm-k8s"
environment  = "dev"
owner        = "ai-team"
# =============================================================================
# Route53 / DNS Configuration
# =============================================================================
domain_name_prefix = "*.test-majd-llm-k8s"
zone_id            = "Z02745981J3FQC8Y0Z4P7"
 ingress_lb_hostname     = "k8s-kubesyst-traefik-21b3b60feb-59606f2ad182c5fa.elb.us-east-2.amazonaws.com"
