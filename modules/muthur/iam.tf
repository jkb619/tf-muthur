data "aws_iam_policy_document" "muthur_server_assume_role" {
  statement {
    sid     = "ECSTaskAccess"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "muthur_server" {
  statement {
    sid = "CloudwatchLogAccess"
    actions = [
      "logs:CreateLog*",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "muthur_server" {
  description = "The core policy allowing basic access for a functioning muthur server."
  name_prefix = "muthur-server-${terraform.workspace}"
  policy      = data.aws_iam_policy_document.muthur_server.json
}

resource "aws_iam_role" "muthur_server" {
  assume_role_policy    = data.aws_iam_policy_document.muthur_server_assume_role.json
  description           = "Starts with the requirements for the muthur server to function."
  force_detach_policies = true
  name_prefix           = "muthur-server-${terraform.workspace}"
  tags                  = local.tags_rendered
}

resource "aws_iam_role_policy_attachment" "muthur_server" {
  role       = aws_iam_role.muthur_server.name
  policy_arn = aws_iam_policy.muthur_server.arn
}

output "role_arn" {
  description = "The ARN of the role the muthur server uses to access credentials."
  value       = aws_iam_role.muthur_server.arn
}

output "role_name" {
  description = "The name of the role the muthur server uses to access credentials."
  value       = aws_iam_role.muthur_server.name
}

output "policy_arn" {
  description = "The ARN of the policy attached to the muthur server role."
  value       = aws_iam_policy.muthur_server.arn
}

output "policy_id" {
  description = "The ID of the policy attached to the muthur server role."
  value       = aws_iam_policy.muthur_server.arn
}

output "policy_name" {
  description = "The name of the policy attached to the muthur server role."
  value       = aws_iam_policy.muthur_server.name
}

