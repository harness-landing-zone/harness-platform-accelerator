terraform {
  # S3 backend — run locally first to initialise:
  # tofu init \
  #   -backend-config="bucket=harness-backend-mk" \
  #   -backend-config="key=harness/platform_accelerator/terraform.tfstate" \
  #   -backend-config="region=us-east-1"
  # The bootstrap_deploy pipeline uses the same bucket/key to maintain state.
  backend "s3" {}

  required_providers {
    harness = {
      source  = "harness/harness"
      version = ">= 0.31"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.1"
    }
  }
}
