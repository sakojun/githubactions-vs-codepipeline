resource "aws_codepipeline" "codepipeline" {
  name     = "${var.prefix}-test-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.example.arn
        FullRepositoryId = var.repository
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.example.name
      }
    }
  }
}

resource "aws_codebuild_project" "example" {
  name          = "${var.prefix}-test-project"
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "codepipeline/buildspec.yml"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.artifact_bucket
}

resource "aws_codestarconnections_connection" "example" {
  name          = "${var.prefix}-example-connection"
  provider_type = "GitHub"
}
