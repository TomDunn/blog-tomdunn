title: Hosting and deploying a static website on Amazon S3
date: 2015-06-28 16:40:24
tags:
    - aws
    - s3
    - web
    - static-website
---

# Overview

Thist post will how to very cheaply host your static website using the Amazon S3 Static Website feature.

## Before you start
Before following along you should already:
* Have an [Amazon AWS](http://aws.amazon.com/) account
* Have access to the AWS Console website
* Be familiar with [Amazon S3](http://aws.amazon.com/s3/)
* Have some static web content you want to host
* Be comfortable using the command line
* Have a domain name (if you want one for your static website)

## To be covered
* Creating and configuring the S3 bucket
* Applying your domain name to the S3 bucket using [Amazon Route53](http://aws.amazon.com/route53/)
* How to use [s3cmd](http://s3tools.org/s3cmd) to deploy your content

# Creating and configuring the S3 Bucket
This step is really simple:
1. Create your S3 bucket
2. In the console select your bucket:
    * click 'Properties'
    * then enable website hosting under the 'Static website hosting' section

You should now have an endpoint for your S3 website. Depending on your bucketname and aws region, your endpoint will look something like '<bucketname>.s3-website-<aws-region>.amazonaws.com'. I recommend placing a simple index.html in the bucket root and making it public.

If you have the domain name example.net and you want S3 to serve content for example.net, your S3 bucket will have to be named 'example.net'.

# Applying the domain name

This step only applies if you have a domain name (like example.net) you want to use. Otherwise you can just use the endpoint provided by S3 and skip this step.

## Delegate DNS to Amazon Route53

1. Go to Route53 in the AWS Console
2. Create a new hosted zone and input your domain name (example.net), keep type as public hosted zone
3. Copy down the name servers for your hosted zone, you will need these next

The next steps will vary depending on your registrar. Essentially what you need to do is override the name servers your registrar uses with the ones from your Route53 hosted zone.

Here is an [example for NameCheap](http://www.mattheye.com/configuring-aws-route53-and-namecheap-domain-names/).

## Alias the domain to your S3 website

1. Select the hosted zone you created in Route53
1. Click 'Create Record Set'
1. Leave Name blank for now (you can repeat this process and add routes for subdomains like www.example.net later if you want)
1. For type, select 'A - IPv4 address'
1. Select yes for the Alias option
1. For alias target, select the S3 bucket you created
1. Leave the rest of the options at their defaults and click create

It may take quite some time for all the DNS settings to propagate, be patient. Assuming all went well you should be able to see the contents of the index.html file in your bucket when you go to the domain in your browser.

# Deploying your content

At this point you can edit the site by uploading files into your S3 bucket via the AWS console or AWS commandline. I will describe another alternative, which is to use [s3cmd](http://s3tools.org/s3cmd). s3cmd provides a nice commandline interface to Amazon S3, for example it makes it really easy to sync a local folder containing your website content to the S3 bucket. Go ahead and install it.

## Create a user/policy for s3cmd

s3cmd needs an AccessKeyId and SecretKey in order to interact with your S3 buckets. I recommend creating an IAM policy and user for s3cmd. In the IAM console create a policy with this body:
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

# creds.sh
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
