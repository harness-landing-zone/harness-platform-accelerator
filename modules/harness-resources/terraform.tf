terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.45.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.1"
    }
  }
}
