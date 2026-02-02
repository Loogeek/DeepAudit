#!/bin/bash
set -e

echo "🧹 1. 清理旧容器和网络..."
docker compose down 2>/dev/null || true
docker compose -f docker-compose.prod.yml down 2>/dev/null || true
docker ps -a | grep deepaudit | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
docker network ls | grep deepaudit | awk '{print $1}' | xargs -r docker network rm 2>/dev/null || true
docker network prune -f

echo "📥 2. 删除旧镜像，强制拉取最新..."
docker rmi ghcr.nju.edu.cn/loogeek/deepaudit-frontend:latest 2>/dev/null || true

echo "🚀 3. 启动服务..."
docker compose -f docker-compose.prod.yml up -d

echo "⏳ 4. 等待服务启动..."
sleep 5

echo "📊 5. 查看服务状态..."
docker compose -f docker-compose.prod.yml ps

echo "✅ 部署完成！"
echo "访问: http://localhost:3001/deepaudit/"
