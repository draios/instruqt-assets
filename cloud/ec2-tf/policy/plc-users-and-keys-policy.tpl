{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:DeleteUser",
                "iam:CreateUser"
            ],
            "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:user/*admin*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "iam:DeleteAccessKey",
                "iam:CreateAccessKey",
                "iam:ListAccessKeys"
            ],
            "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:user/*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Deny",
            "Action": [
                "iam:CreateAccessKey"
            ],
            "Resource": [
              "arn:aws:iam::${AWS_ACCOUNT_ID}:role/*",
              "arn:aws:iam::${AWS_ACCOUNT_ID}:user/*admin*"
            ]
        }
    ]
}