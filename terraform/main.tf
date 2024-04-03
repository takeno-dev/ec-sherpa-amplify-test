variable "user_pool_client_id" {}
variable "user_pool_id" {}
variable "basic_auth_credentials" {}

variable "app_name" {
  type    = string
  default = "amplify_terraform_example"
}

variable "app_env" {
  type = string
  default = "dev"
}

variable "aws_profile" {
    type    = string
    default = "ec-sherpa-staging"
}

variable "aws_default_region" {
    type    = string
    default =  "ap-northeast-1"
}

provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_default_region}"
}

data "aws_caller_identity" "current" {}

# Amplify アプリケーションの作成
resource "aws_amplify_app" "my_app" {
  platform = "WEB_COMPUTE"
  name = var.app_name
  repository = "https://github.com/takeno-dev/ec-sherpa-amplify-test"
  oauth_token  = var.github_oauth_token

  build_spec = <<EOF
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOF

  environment_variables = {
    ENV = var.app_env
    # Cognitoの設定 - terraform apply時に設定する
    NEXT_PUBLIC_USER_POOL_CLIENT_ID="${var.user_pool_client_id}",
    NEXT_PUBLIC_USER_POOL_ID="${var.user_pool_id}",
  }

  auto_branch_creation_config {
    enable_auto_build = true
  }

  enable_basic_auth = true
  basic_auth_credentials = base64encode(var.basic_auth_credentials)
}

variable "github_oauth_token" {}

# Amplify アプリの環境(ブランチ)の作成
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.my_app.id
  branch_name = "main"
  framework = "Next.js - SSR"
  enable_auto_build = true
  stage     = "PRODUCTION"
}


# ドメインを設定
resource "aws_amplify_domain_association" "myapp" {
  app_id      = aws_amplify_app.my_app.id
  domain_name = "stg.ec-sherpa.com"

  sub_domain {
    branch_name = "main" 
    prefix      = "test"
  }
}
