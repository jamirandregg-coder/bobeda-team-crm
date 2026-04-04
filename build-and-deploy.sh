#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
# Bobeda Team App — Build & Deploy Script
# ---------------------------------------------------------------

IMAGE_REPO="${IMAGE_REPO:-bobeda-team/app}"
IMAGE_TAG="${IMAGE_TAG:-1.0.0}"
HELM_RELEASE="${HELM_RELEASE:-bobeda-team}"
HELM_NAMESPACE="${HELM_NAMESPACE:-default}"
HELM_CHART_DIR="$(dirname "$0")/helm/bobeda-team"

build() {
    echo "==> Building Docker image: ${IMAGE_REPO}:${IMAGE_TAG}"
    docker build -t "${IMAGE_REPO}:${IMAGE_TAG}" .
    echo "==> Build complete"
}

push() {
    echo "==> Pushing image: ${IMAGE_REPO}:${IMAGE_TAG}"
    docker push "${IMAGE_REPO}:${IMAGE_TAG}"
    echo "==> Push complete"
}

deploy() {
    echo "==> Deploying Helm chart: ${HELM_RELEASE} to namespace ${HELM_NAMESPACE}"
    helm upgrade --install "${HELM_RELEASE}" "${HELM_CHART_DIR}" \
        --namespace "${HELM_NAMESPACE}" \
        --create-namespace \
        --set image.repository="${IMAGE_REPO}" \
        --set image.tag="${IMAGE_TAG}" \
        --wait \
        --timeout 120s
    echo "==> Deploy complete"
    echo ""
    echo "Check status:  kubectl get pods -n ${HELM_NAMESPACE} -l app.kubernetes.io/name=bobeda-team"
    echo "Port forward:  kubectl port-forward -n ${HELM_NAMESPACE} svc/${HELM_RELEASE}-bobeda-team 8080:80"
}

case "${1:-help}" in
    build)  build ;;
    push)   push ;;
    deploy) deploy ;;
    all)    build && push && deploy ;;
    *)
        echo "Usage: $0 {build|push|deploy|all}"
        exit 1
        ;;
esac