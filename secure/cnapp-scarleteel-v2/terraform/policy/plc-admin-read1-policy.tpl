{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:GetPolicyVersion",
                "iam:ListRoleTags",
                "iam:GetGroup",
                "license-manager:ListUsageForLicenseConfiguration",
                "iam:ListAttachedRolePolicies",
                "iam:ListAttachedUserPolicies",
                "iam:ListAttachedGroupPolicies",
                "license-manager:ListAssociationsForLicenseConfiguration",
                "iam:ListPolicyTags",
                "iam:ListRolePolicies",
                "iam:ListAccessKeys",
                "iam:GetPolicy",
                "iam:ListGroupPolicies",
                "iam:GetAccessKeyLastUsed",
                "iam:ListEntitiesForPolicy",
                "iam:ListUserPolicies",
                "iam:ListPolicyVersions",
                "fms:GetPolicy",
                "iam:GetUserPolicy",
                "iam:ListGroupsForUser",
                "license-manager:ListLicenseManagerReportGenerators",
                "iam:GetGroupPolicy",
                "iam:GetUser",
                "license-manager:ListLicenseVersions",
                "license-manager:ListFailuresForLicenseConfigurationOperations",
                "iam:ListUserTags"
            ],
            "Resource": [
                "arn:aws:license-manager::${AWS_ACCOUNT_ID}:license:*",
                "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/*",
                "arn:aws:iam::${AWS_ACCOUNT_ID}:group/*",
                "arn:aws:iam::${AWS_ACCOUNT_ID}:role/*",
                "arn:aws:iam::${AWS_ACCOUNT_ID}:user/*",
                "arn:aws:fms:*:${AWS_ACCOUNT_ID}:policy/*"
            ]
        }
    ]
}