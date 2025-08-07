resource "aws_iam_role" "external-dns" {
  name = "${local.name}-pod-role-for-external-dns"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": "arn:aws:iam::522814736516:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${local.cluster_issuer_id}"
        },
        "Condition": {
          "StringEquals": {
            "oidc.eks.us-east-1.amazonaws.com/id/${local.cluster_issuer_id}:aud": "sts.amazonaws.com",
            "oidc.eks.us-east-1.amazonaws.com/id/${local.cluster_issuer_id}:sub": "system:serviceaccount:default:external-dns"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "parameter-store"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Route53Access",
          "Effect" : "Allow",
          "Action" : [
            "route53:*"
          ],
          "Resource" : "*"
        }
      ]
    })
  }

}

variable "components" {
  default = ["frontend", "cart", "catalogue", "user", "shipping", "payment"]
}

resource "aws_iam_role" "app-ssm" {
  count = length(var.components)
  name = "${local.name}-pod-role-for-${var.components[count.index]}-ssm"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": "arn:aws:iam::522814736516:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/${local.cluster_issuer_id}"
        },
        "Condition": {
          "StringEquals": {
            "oidc.eks.us-east-1.amazonaws.com/id/${local.cluster_issuer_id}:aud": "sts.amazonaws.com",
            "oidc.eks.us-east-1.amazonaws.com/id/${local.cluster_issuer_id}:sub": "system:serviceaccount:default:${var.components[count.index]}"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "${var.components[count.index]}-parameter-store"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "SSM",
          "Effect" : "Allow",
          "Action" : [
            "ssm:DescribeParameters",
            "ssm:GetParameterHistory",
            "ssm:GetParametersByPath",
            "ssm:GetParameters",
            "ssm:GetParameter",
            "kms:Decrypt"
          ],
          "Resource" : "*"
        }
      ]
    })
  }

}