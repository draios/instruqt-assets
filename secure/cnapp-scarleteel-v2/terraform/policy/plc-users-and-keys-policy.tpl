{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AreThereOtherMachines",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*"
            ],
            "Resource": "*"
        },
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
        },
        {
            "Sid": "s3Reader",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*",
                "s3:PutBucketPolicy"
            ],
            "Resource": [
                "arn:aws:s3:::TEMPLATE_BUCKET_NAME",
                "arn:aws:s3:::TEMPLATE_BUCKET_NAME/*"
            ]
        }
    ]
}
