terraform {
  # GCS backend — run locally first to initialise:
  # tofu init \
  #   -backend-config="bucket=harness-backend-mk" \
  #   -backend-config="prefix=harness/platform_accelerator"
  # The bootstrap_deploy pipeline uses the same bucket/prefix to maintain state.

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
