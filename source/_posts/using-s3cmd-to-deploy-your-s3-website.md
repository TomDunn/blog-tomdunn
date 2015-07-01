title: Using s3cmd to deploy your S3 Website
tags:
  - aws
  - s3
  - web
  - static-website
  - s3cmd
date: 2015-06-30 22:14:33
---


# Overview

This short post describes how to use [s3cmd](http://s3tools.org/s3cmd) to deploy content to your [Amazon S3 Website](http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html). This is useful if you are using some sort of [static website generator](http://nilclass.com/courses/what-is-a-static-website/) and want to upload the content to an S3 bucket (where it can be served to your users).

## Before you start

This post assumes you have already set up your static website. If you need to, follow this [AWS walkthrough](http://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html) to set up your site with a custom domain. One gotcha - if your domain name is 'example.net', then your S3 bucket needs to be named exactly 'example.net'.

# Deploying your content

## Create a user/policy for s3cmd

s3cmd needs credentials in order to interact with your S3 buckets. I recommend not using your root credentials and instead creating an IAM policy and user for s3cmd. In the IAM console create a policy with this body:

``` JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1397834652000",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Sid": "Stmt1397834745000",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_BUCKET_NAME",
                "arn:aws:s3:::YOUR_BUCKET_NAME/*"
            ]
        }
    ]
}
```

Now create an IAM user and save the access key id/secret. Apply the policy from above to the user you created. I usually save the credentials into a shell script like so:

``` bash
#!/bin/bash

# creds.sh - DO NOT SOURCE CONTROL THESE CREDENTIALS. IF YOU DO, DEACTIVATE THEM IMMEDIATELY.
export DEPLOY_KEY_ID='PUT ACCESS ID IN HERE'
export DEPLOY_KEY_SECRET='PUT SECRET HERE'
```

and then run:

``` bash
source ./creds.sh
```

This makes the credentials available via the environment variables $DEPLOY_KEY_ID and $DEPLOY_KEY_SECRET.

## Write the deploy script

Now, to wrap everything up with the deployment script:

``` bash
#!/bin/bash

# deploy.sh

s3cmd sync DIRECTORY_CONTAINING_YOUR_WEBSITE_CONTENT/* s3://YOUR_BUCKET_NAME/ \
    --guess-mime-type \
    --no-mime-magic \
    --add-header=cache-control:public,max-age=7200 \
    --no-preserve \
    --acl-public \
    --access_key=$DEPLOY_KEY_ID \
    --secret_key=$DEPLOY_KEY_SECRET
```

You can read about the various flags I used [here](http://s3tools.org/usage). I am using the --add-header option to add some basic [cache-control](http://www.mobify.com/blog/beginners-guide-to-http-cache-headers/) to anything served from the S3 bucket.


