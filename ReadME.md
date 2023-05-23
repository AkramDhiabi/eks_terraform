# Create IAM OIDC provider EKS using Terraform¶
To manage permissions for your applications that you deploy in Kubernetes. You can either attach policies to Kubernetes nodes directly. In that case, every pod will get the same access to AWS resources. Or you can create OpenID connect provider, which will allow granting IAM permissions based on the service account used by the pod. File name is iam-oidc.tf


testing the provider first before deploying the autoscaller. It can save a lot of time. 
File name is terraform iam-sa-test.tf

# Steps:

terraform apply
aws eks --region us-east-1 update-kubeconfig --name demo
kubectl get svc ( to test connectivity to the cluster)
kubectl apply -f k8s/aws-test.yaml

Now, let's check if can list S3 buckets in:
  kubectl exec aws-cli -- aws s3api list-buckets ( it won't work as it misses the sa annotation)

Let's add missing annotation to the service account:

``
metadata:
  ...
  annotation:
    eks.amazonaws.com/role-arn: arn:aws:iam::424432388155:role/test-oidc
``
and redeploy the pod:
  kubectl delete -f k8s/aws-test.yaml
  kubectl apply -f k8s/aws-test.yaml   

Try listing the bucket again:
kubectl exec aws-cli -- aws s3api list-buckets


# Create public load balancer on EKS

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/public-lb.yaml

Find load balancer in AWS console by name. Verify that LB was created in public subnets


# Create private load balancer on EKS
Sometimes if you have a large infrastructure with many different services, you have a requirement to expose the application only within your VPC. For that, you can create a private load balancer. To make it private, you need additional annotation: aws-load-balancer-internal and then provide the CIDR range. Usually, you use 0.0.0.0/0 to allow any services within your VPC to access it. Give it a name k8s/private-lb.yaml.

kubectl apply -f k8s/private-lb.yaml

# Deploy EKS cluster autoscaler
Finally, we got to the EKS autoscaller. We will be using OpenID connect provider to create an IAM role and bind it with the autoscaller. Let's create an IAM policy and role first. It's similar to the previous one, but autoscaller will be deployed in the kube-system namespace. File name is iam-autoscaler.tf.

terraform apply
kubectl apply -f k8s/cluster-autoscaler.yaml

You can verify that the autoscaler pod is up and running with the following command:
kubectl get pods -n kube-system

It's a good practice to check logs for any errors:
kubectl logs -l app=cluster-autoscaler -n kube-system -f

# EKS cluster auto scaling demo¶

Verify that AG (aws autoscaling group) has required tags:
``
k8s.io/cluster-autoscaler/<cluster-name> : owned
k8s.io/cluster-autoscaler/enabled : TRUE
``

Split the terminal screen. In the first window run:

watch -n 1 -t kubectl get pods

In the second window run:

watch -n 1 -t kubectl get nodes

Now, to trigger autoscaling, increase replica for nginx deployment from 1 to 5.

kubectl apply -f k8s/deployment.yaml