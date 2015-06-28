#!/bin/bash

s3cmd sync ./public/* s3://tomdunn.net/ \
    --guess-mime-type \
    --no-mime-magic \
    --add-header=cache-control:public,max-age=7200 \
    --no-preserve \
    --acl-public \
    --access_key=$DEPLOY_KEY_ID \
    --secret_key=$DEPLOY_KEY_SECRET \
    --skip-existing

