update_settings ( max_parallel_updates = 5 , k8s_upsert_timeout_secs = 60 , suppress_unused_image_warnings = None )

allow_k8s_contexts('colima')
allow_k8s_contexts('local')

load('ext://restart_process', 'docker_build_with_restart')
load('ext://helm_resource', 'helm_resource', 'helm_repo')

###############################################
# Using local build of k8s-gateway helm chart #
###############################################
IMG = 'localhost:5000/coredns'

def binary():
    return "CGO_ENABLED=0  GOOS=linux GOARCH=amd64 GO111MODULE=on go build cmd/coredns.go"

local_resource('recompile', binary(), deps=['cmd', 'gateway.go', 'kubernetes.go', 'setup.go', 'apex.go'])

docker_build_with_restart(IMG, '.',
    dockerfile='tilt.Dockerfile',
    entrypoint=['/coredns'], 
    live_update=[
        sync('./coredns', '/coredns'),
        ]
)
# CoreDNS with updated RBAC
k8s_yaml(helm(
    './charts/k8s-gateway',
    namespace="kube-system",
    name='excoredns',
    values=['./test/infra/k8s-gateway/k8s-gateway-values.yaml'],
    )
)
k8s_resource('excoredns-k8s-gateway', resource_deps=['gateway-api-crds'])

####################################################
# Make sure the GatewayAPI CRDs are deployed first #
####################################################
local_resource(
    'gateway-api-crds',
    cmd='kubectl apply -f ./test/infra/gateway-api/crds.yml',
    deps=['./test/infra/gateway-api/crds.yml']
)
k8s_kind('GatewayClass', api_version='gateway.networking.k8s.io/v1')
k8s_kind('Gateway', api_version='gateway.networking.k8s.io/v1')
k8s_kind('GRPCRoute', api_version='gateway.networking.k8s.io/v1')
k8s_kind('HTTPRoute', api_version='gateway.networking.k8s.io/v1')
k8s_kind('TLSRoute', api_version='gateway.networking.k8s.io/v1alpha2')

########################################
# Cilium implements ingress/GatewayAPI #
########################################
helm_repo(
    name="cilium-repo",
    url="https://helm.cilium.io",
)
helm_resource(
    name="cilium-install",
    chart="cilium-repo/cilium",
    namespace="kube-system",
    flags=[
        '--values=./test/infra/cilium/helm-values.yaml',
        '--version=1.17.1',
    ],
    resource_deps=['gateway-api-crds', 'cilium-repo']
)

local_resource(
    'cilium-lb',
    cmd='kubectl apply -f ./test/infra/cilium/cilium-lb.yaml',
    resource_deps=['cilium-install'],
    deps=['./test/infra/cilium/cilium-lb.yaml']
)

#############################################
# Nginxinc implements VirtualServer/Ingress #
#############################################
helm_resource(
    name="nginxinc",
    chart="oci://ghcr.io/nginxinc/charts/nginx-ingress",
    namespace="kube-system",
    flags=[
        '--values=./test/infra/nginxinc-kubernetes-ingress/values.yaml',
        '--version=2.0.0',
    ],
    resource_deps=['cilium-lb'],
)

######################################
# Cert-manager implements Challenges #
######################################
helm_repo(
    name="jetstack",
    url="https://charts.jetstack.io",
)
helm_resource(
    name="cert-manager",
    chart="jetstack/cert-manager",
    namespace="kube-system",
    flags=[
        '--values=./test/infra/cert-manager/values.yaml',
        '--version=1.17.1',
    ],
    resource_deps=['jetstack', 'cilium-install']
)
helm_resource(
    name="cert-manager-webhook",
    chart="oci://ghcr.io/pinax-network/charts/cert-manager-webhook-pinax",
    namespace="kube-system",
    flags=[
        '--version=0.1.0',
        '--set=certManager.namespace=kube-system',
    ],
    resource_deps=['cert-manager'],
)

##################################
# Backend deployment for testing #
##################################
local_resource(
    'test-app',
    cmd='kubectl apply -k ./test/app',
    resource_deps=['cilium-lb', 'excoredns-k8s-gateway', 'cert-manager-webhook', 'nginxinc'],
    deps=[
        './test/app/kustomization.yaml',
        './test/app/backend.yml',
        './test/app/ingress.yaml',
        './test/app/service.yaml',
        './test/app/challenge.yaml',
        './test/app/gateway-api.yaml',
        './test/app/virtual-server.yaml',
    ]
)
