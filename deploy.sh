#!/bin/bash

deploy_infrastructure() {
    # Navigate to the infrastructure directory
    cd game-dev-infrastructure

    echo "Building lambda requirements" 
    rm -rf lambda_build
    mkdir lambda_build
    pip install -r lambda_code/requirements.txt -t lambda_build
    cp lambda_code/*.py lambda_build


    # Deploy the infrastructure
    echo "Deploying AWS infrastructure..."
    cdk deploy --outputs-file ./outputs.json --all

    # Check if the deployment was successful
    if [ $? -ne 0 ]; then
        echo "Infrastructure deployment failed."
        exit 1
    fi

    cd ..
}

deploy_frontend() {
    # Read outputs (S3 bucket name and CloudFront distribution ID)
    BUCKET_NAME=$(cat game-dev-infrastructure/outputs.json | jq -r '.["FrontendStack"].BucketName')
    DISTRIBUTION_ID=$(cat game-dev-infrastructure/outputs.json | jq -r '.["FrontendStack"].DistributionId')
    IDENTITY_POOL_ID=$(cat game-dev-infrastructure/outputs.json | jq -r '.["CognitoStack"].IdentityPoolId')
    USER_POOL_ID=$(cat game-dev-infrastructure/outputs.json | jq -r '.["CognitoStack"].UserPoolId')
    USER_POOL_CLIENT_ID=$(cat game-dev-infrastructure/outputs.json | jq -r '.["CognitoStack"].UserPoolClientId')
    # Navigate to the frontend directory
    cd game-dev-frontend

    # Deploy the frontend
    echo "Deploying the frontend..."
    bash ./deploy.sh $BUCKET_NAME $DISTRIBUTION_ID $IDENTITY_POOL_ID $USER_POOL_ID $USER_POOL_CLIENT_ID

    # Check deployment status
    if [ $? -ne 0 ]; then
        echo "Frontend deployment failed."
        exit 1
    fi

    echo "Deployment completed successfully."
}


deploy_infrastructure
deploy_frontend
