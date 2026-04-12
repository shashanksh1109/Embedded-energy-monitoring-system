#!/bin/bash
# aws-up.sh — Spin up the full AWS stack
# Usage: ./scripts/aws-up.sh
# Takes ~10 minutes on first run, ~5 minutes on subsequent runs

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ACCOUNT_ID="993268716712"
REGION="us-east-1"
ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
CLUSTER="energy-management-cluster"

echo ""
echo "================================================================"
echo "  ENERGY MANAGEMENT SYSTEM — AWS STARTUP"
echo "================================================================"

# ─── Step 1: Terraform ───────────────────────────────────────────────
echo ""
echo "[1/5] Provisioning infrastructure with Terraform..."
cd "$PROJECT_DIR/Terraform"
terraform apply -auto-approve
echo "  ✓ Infrastructure ready"

# ─── Step 2: ECR Login ───────────────────────────────────────────────
echo ""
echo "[2/5] Authenticating Docker to ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR
echo "  ✓ Docker authenticated"

# ─── Step 3: Build and push images ───────────────────────────────────
echo ""
echo "[3/5] Building and pushing Docker images..."

echo "  → Backend (Spring Boot)..."
cd "$PROJECT_DIR/Backend"
mvn clean package -DskipTests -q
docker build -t $ECR/energy-management/backend:latest . -q
docker push $ECR/energy-management/backend:latest -q

echo "  → Gateway (Python)..."
cd "$PROJECT_DIR/Gateway"
docker build -t $ECR/energy-management/gateway:latest . -q
docker push $ECR/energy-management/gateway:latest -q

echo "  → Embedded (sensor/hvac/power)..."
cd "$PROJECT_DIR/Embedded"
docker build -t energy-embedded . -q
for svc in sensor hvac power; do
  docker tag energy-embedded $ECR/energy-management/$svc:latest
  docker push $ECR/energy-management/$svc:latest -q
done

echo "  → Frontend (React)..."
cd "$PROJECT_DIR/Terraform"
ALB_DNS=$(terraform output -raw alb_dns_name)
cd "$PROJECT_DIR/Frontend"
npm ci --silent
VITE_API_URL="http://$ALB_DNS/api" npm run build --silent
aws s3 sync dist/ \
  s3://energy-management-frontend-$ACCOUNT_ID/ \
  --delete --region $REGION --quiet
echo "  ✓ All images pushed, frontend deployed"

# ─── Step 4: Force ECS to use new images ─────────────────────────────
echo ""
echo "[4/5] Deploying services to ECS..."
for svc in backend gateway sensor hvac power; do
  aws ecs update-service \
    --cluster $CLUSTER \
    --service energy-management-$svc \
    --force-new-deployment \
    --region $REGION \
    --query "service.serviceName" \
    --output text
done
echo "  ✓ ECS services updated"

# ─── Step 5: Print URLs ──────────────────────────────────────────────
echo ""
echo "[5/5] Getting endpoints..."
cd "$PROJECT_DIR/Terraform"
FRONTEND_URL=$(terraform output -raw frontend_website_url)
ALB_DNS=$(terraform output -raw alb_dns_name)

echo ""
echo "================================================================"
echo "  SYSTEM IS UP"
echo "================================================================"
echo ""
echo "  Frontend : http://$FRONTEND_URL"
echo "  API      : http://$ALB_DNS/api/health"
echo "  Login    : admin / energy123"
echo ""
echo "  NOTE: ECS containers take 2-3 minutes to start."
echo "  NOTE: If RDS is fresh (first deploy or after destroy),"
echo "        run: ./scripts/load-schema.sh"
echo ""
echo "  To shut down: ./scripts/aws-down.sh"
echo ""
