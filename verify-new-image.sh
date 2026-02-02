#!/bin/bash
set -e

echo "========== 1. 停止旧容器 =========="
docker compose -f docker-compose.prod.yml down 2>/dev/null || true

echo ""
echo "========== 2. 删除旧的前端镜像 =========="
docker rmi ghcr.nju.edu.cn/loogeek/deepaudit-frontend:latest 2>/dev/null || echo "镜像已删除或不存在"

echo ""
echo "========== 3. 拉取最新镜像 =========="
docker pull ghcr.nju.edu.cn/loogeek/deepaudit-frontend:latest

echo ""
echo "========== 4. 查看新镜像创建时间 =========="
docker inspect ghcr.nju.edu.cn/loogeek/deepaudit-frontend:latest --format='创建时间: {{.Created}}'

echo ""
echo "========== 5. 启动服务 =========="
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "========== 6. 等待服务启动 (10秒) =========="
sleep 10

echo ""
echo "========== 7. 查看容器状态 =========="
docker compose -f docker-compose.prod.yml ps

echo ""
echo "完成！现在开始验证..."
