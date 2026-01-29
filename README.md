# rapyd-sentinel
A threat intelligence platform

### Project Structure
The project is divided into 3 sections:
  1. [infastructure](./infrastructure/) : It stores the terraform code for aws resources of application infrastructure.
  2. [application](./application/) : It stores kubernetes manifests for application.
  3. [ci_cd](./ci_cd) : It stores the terraform code for CI/CD Operations.

### Instructions to use and deploy the project from scratch
<details><summary>Step 1 : Pre-Requisites - Infrastructure Deployment</summary>
  a) Since you are deploying infrastructure and applications manually first and not with CI/CD, Please configure your local aws profile to have administrator access.
  b) Create an s3 bucket to store the terraform state.
  c) Switch to infrastructure directory. Update terraform block and aws provider block with your profile, region and credentials in providers.tf file.  
  d) Run `terraform init --upgrade` to initalize the backend.

  NOTE: The project is written with terraform version 1.14.X. Please make sure you use the exact version or update it accordingly.
</details>

<details><summary>Step 2 : Infrastructure Deployment</summary>
  a) Switch to infrastructure/backend directory. Update api_access_config.access_cidrs attribute of eks module attribute with your local machine IP. This setting will make the EKS API public which will be used later to deploy application manifest. Do the same thing in infrastructure/gateway.
  b) Run Command : terraform validate && terraform plan -out=tfplan. This will generate your plan and store it in a tfplan file. Go through the list of resources getting created.
  c) Once everything is approved, Run Command : terraform apply. Wait for the resources to get created.
  d) It should create:
     - VPCs : vpc-gateway and vpc-backend
     - EKS Clusters : eks-gateway and eks-backend
     - Private VPC Peering with Transit Gateway 
     - Security group rules to allow traffic from cross-VPC/Cross-EKS Worker nodes.
     - Required IAM roles and resources to deploy AWS Loadbalancer Controller
</details>

<details><summary>Step 3 : Pre-requisite - Application Deployment </summary>
  a) Create EKS Access Entries for your local aws user and associate cluster administrator policy to it for both EKS Clusters. 

     ```yaml
     aws eks create-access-entry --cluster-name {cluster-name} --principal-arn {USER_IAM_ROLE_ARN} --type STANDARD --region {REGION} --profile {PROFILE}

     aws eks associate-access-policy --cluster-name {cluster-name} --principal-arn {USER_IAM_ROLE_ARN} --policy-arn arn:aws:eks::aws:cluster-access-policy/ AmazonEKSClusterAdminPolicy --access-scope type=cluster --region {REGION} --profile {PROFILE}
     ```

  b) Update local kube-config for both eks clusters.

     ```yaml
     aws eks update-kubeconfig --name {cluster-name} --region {REGION} --profile {PROFILE}
     ```

  c) you will now be able to communicate with EKS API server and can deploy manifests.
</details>

<details><summary>Step 4 : Application Deployment </summary>
  a) Install AWS Load Balancer Controller in both EKS. 

     ```yaml
     i)  Install cert-manager CRDS.
         kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v{CERT_MANAGER_VERSION}/cert-manager.yaml

     ii) Download AWS Load Balancer Controller manifest and update --cluster-name in Deployment. The file is already downloaded in application/{application} directory
         wget https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v3.0.0/v3_0_0_full.yaml -o load-balancer-controller.yaml
         kubectl apply -f load-balancer-controller.yaml
     ```

  b) Switch the kube context to communicate with eks-backend cluster. Go to application/backend directory and run : kubectl apply -f backend.yaml. This will create:
     - Namespace 
     - ConfigMap serving as index.html mounted in backend pod 
     - Deployment
     - Service of type Loadbalancer(internal) Allowing Traffic only from gateway VPC CIDR
     - Network Policy to deny all traffic  

  c) Note the DNS of the generated NLB for backend application.
  d) Go to application/gateway directory and update the proxy configuration in configmap manifest to proxy traffic to backend NLB. Switch the kube context to communicate with eks-gateway cluster and run : kubectl apply -f backend.yaml. This will create: 
     - Namespace
     - ConfigMap serving as index.html mounted in gateway pod.
     - Deployment
     - Service of type Loadbalancer(public) Allowing Traffic only from Internet.
</details>

<details><summary>Step 5 : Application Validation </summary>
  a) Browse the DNS of Gateway NLB. It should render the content of backend app.
</details>

<details><summary>Step 6 : Setup GitHub OIDC federation for CI/CD</summary>
  a) Switch to ci_cd directory and apply terraform. It will create required role and policies to Setup GitHub OIDC federation for CI/CD
</details>

<details><summary>Step 7 : Use Roles created in step 6 in CI/CD Workflows</summary>
  a) Update github action in CI/CD Worflows : aws-actions/configure-aws-credentials@v5
```yaml
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: "arn:aws:iam::Account-name:role/GITHUB_OIDC_FEDERATED_ROLE"
          aws-region: ${{ env.AWS_REGION }}
```

</details>

## How networking is configured between VPCs & EKS clusters
```yaml
VPC: vpc-gateway (10.120.0.0/16)           VPC: vpc-backend (10.110.0.0/16)
+------------------------------+         +----------------------------------+
| Private Subnets              |         | Private Subnets                  |
|                              |         |                                  |
| Private Route Table          |         | Private Route Table              |
|  10.120.1.0/24 <-------------+ Transit +----> 10.110.1.0/16               |
|  10.120.2.0/24               |   GW    |      10.110.2.0/16               |
|                              |         |                                  |
| [eks-gateway-workers]        |         | [eks-backend-workers]            |
|  SG: allow 10.110.0.0/16     |         |  SG: allow 10.120.0.0/16         |
+------------------------------+         +----------------------------------+
```

Cross-VPC communication is being done via a Transit Gateway where private subnets of both vpcs are attached to the transit gateway as attachment resource followed by creating routes in private route tables of both VPCs for routing inter-vpc traffic via transit gateway .

Cross-EKS-workers communication is done by adding security group rules to worker nodes security group to allow traffic from each other VPC's CIDR Range.


## How the proxy talks to the backend
The `backend` application(nginx) running in cluster `eks-backend` consists of a service object of type Loadbalancer. It deploys an Internal NLB accepting traffic only from CIDR range of `vpc-gateway`.

The `gateway` application(nginx proxy) running in cluster `eks-gateway` is configured to proxy all its traffic coming on port 80 to private DNS name of Internal NLB for `backend` application. 

In this way, the proxy talks to the backend app internally.


## CI/CD pipeline structure
There are two workflow files : infra.yaml(for terraform deployment) and app.yaml(for application deployment).
Both are supposed to run on any pull requests and push to main branch. 
For Pull requests, The changes will only be tested or dry run.
For push events, the CI will perform the operations.

NOTE: The CIs are not tested because of time-limit and hence, turned off for any events.

## Trade-offs due to the 3-day limit
1. Used dockerhub rather than ECR for application images repository. This required me to add NAT-GW to vpc-backend, to reach out to dockerhub, which should otherwise have been purely private and should have used VPC Endpoints
1. Although wrote the CI/CD workflows and created Github OIDC federation setup but was unable to test the CI/CD due to time limit.
2. To keep the setup simple and fast, Used NLB as a frontend of gateway application. ALB makes more sense here because it gives much better traffic filter abilities like WAF and fully managed security groups.


## Cost optimization notes
1. Use `t4g.medium`, `SPOT` instances for EKS workers for cost optimization. This instance is general purpose, graviton based which are comparatively cheaper. Currently it is set to ON_DEMAND just for the assignment purpose.
2. Used Network Load Balancers as frontend for both backend and gateway application. NLB is cheaper than ALB and it made sense to use NLB as there was only one application to serve which didn't require a path based routing.

## Future Roadmap
1. Apply cloudwatch alerts for the entire infrastructure
   - EKS worker node resource usage alerts
   - NAT-GW usage alerts
   - Loadbalancer traffic alerts
   - CDN + WAF + ALB implementations in front of Gateway app for caching purposes or preventing DdOS attacks.
2. Implement observability on applications
   - Integrate EKS Cluster with ELK Stack, prometheus-grafana, logzio, axiom or any other application log & metrics monitoring system
   - Implement pod crash alerts
3. Implement Karpenter to automate node provisioning and improving Scaling & Efficiency
4. Creating helm charts for applications for easier deployments
5. Implement GitOps practices such as Argo CD or Flux for better CI/CD Flow
6. Implement Service Mesh like istio to encrypt traffic between pods
