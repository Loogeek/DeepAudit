#!/bin/bash

# DeepAudit 前端镜像一键构建和发布脚本
# 使用方法: ./simple-build.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DeepAudit 前端镜像构建和发布工具${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}\n"

# 确保在正确的目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo -e "${YELLOW}当前目录: $(pwd)${NC}\n"

# ============================================
# 步骤 1: 本地构建
# ============================================
echo -e "${YELLOW}[步骤 1/4] 本地构建镜像...${NC}"
echo -e "${BLUE}这可能需要 10-20 分钟，请耐心等待...${NC}\n"

docker build -t deepaudit-frontend:test .

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ 镜像构建成功！${NC}\n"
else
    echo -e "\n${RED}✗ 镜像构建失败${NC}"
    exit 1
fi

# ============================================
# 步骤 2: 本地测试
# ============================================
echo -e "${YELLOW}[步骤 2/4] 本地测试镜像...${NC}"

# 清理旧的测试容器
docker rm -f deepaudit-frontend-test 2>/dev/null || true

# 启动测试容器
docker run -d --name deepaudit-frontend-test -p 3001:80 deepaudit-frontend:test

echo -e "${GREEN}✓ 测试容器已启动${NC}"
echo -e "${BLUE}访问地址: http://localhost:3001/deepaudit/${NC}\n"

# 等待容器启动
sleep 3

# 测试访问
echo -e "${YELLOW}测试访问...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/deepaudit/ | grep -q "200"; then
    echo -e "${GREEN}✓ 访问测试成功！${NC}\n"
else
    echo -e "${YELLOW}⚠ 自动测试失败，请手动访问 http://localhost:3001/deepaudit/${NC}\n"
fi

# 询问是否继续
echo -e "${YELLOW}请在浏览器中访问: ${BLUE}http://localhost:3001/deepaudit/${NC}"
echo -e "${YELLOW}确认功能正常后，按任意键继续...${NC}"
read -n 1 -s

# 清理测试容器
docker rm -f deepaudit-frontend-test
echo -e "${GREEN}✓ 测试容器已清理${NC}\n"

# ============================================
# 步骤 3: 选择镜像仓库
# ============================================
echo -e "${YELLOW}[步骤 3/4] 选择镜像仓库${NC}"
echo "1) Docker Hub（国际，可能需要翻墙）"
echo "2) 阿里云容器镜像服务（推荐，国内快）"
echo "3) 仅本地构建，不推送"
read -p "请选择 (1-3): " choice

case $choice in
    1)
        echo -e "\n${YELLOW}Docker Hub 配置${NC}"
        read -p "请输入你的 Docker Hub 用户名: " username
        
        if [ -z "$username" ]; then
            echo -e "${RED}错误: 用户名不能为空${NC}"
            exit 1
        fi
        
        REGISTRY_IMAGE="${username}/deepaudit-frontend:latest"
        
        echo -e "${BLUE}登录 Docker Hub...${NC}"
        docker login
        
        echo -e "${BLUE}打标签: ${REGISTRY_IMAGE}${NC}"
        docker tag deepaudit-frontend:test "${REGISTRY_IMAGE}"
        
        echo -e "${BLUE}推送镜像到 Docker Hub...${NC}"
        echo -e "${YELLOW}这可能需要 5-10 分钟...${NC}"
        docker push "${REGISTRY_IMAGE}"
        
        COMPOSE_IMAGE="${REGISTRY_IMAGE}"
        ;;
        
    2)
        echo -e "\n${YELLOW}阿里云容器镜像服务配置${NC}"
        echo -e "${BLUE}提示: 完整地址格式为 registry.cn-[地域].aliyuncs.com/[命名空间]${NC}"
        echo -e "${BLUE}示例: registry.cn-hangzhou.aliyuncs.com/mycompany${NC}"
        read -p "请输入阿里云仓库地址: " aliyun_url
        
        if [ -z "$aliyun_url" ]; then
            echo -e "${RED}错误: 仓库地址不能为空${NC}"
            exit 1
        fi
        
        REGISTRY_IMAGE="${aliyun_url}/deepaudit-frontend:latest"
        REGISTRY_HOST="${aliyun_url%%/*}"
        
        echo -e "${BLUE}登录阿里云镜像服务...${NC}"
        docker login "${REGISTRY_HOST}"
        
        echo -e "${BLUE}打标签: ${REGISTRY_IMAGE}${NC}"
        docker tag deepaudit-frontend:test "${REGISTRY_IMAGE}"
        
        echo -e "${BLUE}推送镜像到阿里云...${NC}"
        echo -e "${YELLOW}这可能需要 5-10 分钟...${NC}"
        docker push "${REGISTRY_IMAGE}"
        
        COMPOSE_IMAGE="${REGISTRY_IMAGE}"
        ;;
        
    3)
        echo -e "${GREEN}仅本地构建完成${NC}"
        echo -e "${BLUE}镜像名称: deepaudit-frontend:test${NC}"
        echo -e "${YELLOW}提示: 如果需要推送，请重新运行此脚本${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}✓ 镜像推送成功！${NC}\n"

# ============================================
# 步骤 4: 更新配置文件说明
# ============================================
echo -e "${YELLOW}[步骤 4/4] 配置文件更新说明${NC}\n"

cat << EOF
${GREEN}✅ 镜像已成功推送到仓库${NC}
${BLUE}镜像地址: ${REGISTRY_IMAGE}${NC}

${YELLOW}接下来需要手动完成以下步骤:${NC}

1️⃣  ${BLUE}更新 docker-compose.prod.yml${NC}
   
   编辑文件: ../docker-compose.prod.yml
   
   将第 90 行改为:
   ${GREEN}frontend:
     image: ${COMPOSE_IMAGE}${NC}

2️⃣  ${BLUE}更新 docker-compose.prod.cn.yml${NC} (如果使用国内镜像)
   
   编辑文件: ../docker-compose.prod.cn.yml
   
   将第 88 行改为:
   ${GREEN}frontend:
     image: ${COMPOSE_IMAGE}${NC}

3️⃣  ${BLUE}提交到 GitHub${NC}
   
   ${GREEN}cd ..
   git add docker-compose.prod.yml docker-compose.prod.cn.yml
   git commit -m "更新前端镜像路径为 /deepaudit/"
   git push${NC}

4️⃣  ${BLUE}验证部署${NC}
   
   同事可以使用以下命令部署:
   ${GREEN}curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/DeepAudit/main/docker-compose.prod.yml | docker compose -f - up -d${NC}
   
   或直接拉取你的镜像:
   ${GREEN}docker pull ${COMPOSE_IMAGE}${NC}

${YELLOW}📋 快速编辑命令:${NC}

# 使用 sed 自动替换（Mac）
sed -i '' 's|image: ghcr.io/lintsinghua/deepaudit-frontend:latest|image: ${COMPOSE_IMAGE}|g' ../docker-compose.prod.yml

# 或使用 vim 手动编辑
vim ../docker-compose.prod.yml

EOF

# 询问是否自动更新
echo -e "\n${YELLOW}是否自动更新 docker-compose.prod.yml？(y/N)${NC}"
read -p "> " auto_update

if [[ $auto_update =~ ^[Yy]$ ]]; then
    cd .. || exit 1
    
    # 备份原文件
    cp docker-compose.prod.yml docker-compose.prod.yml.backup
    
    # Mac 和 Linux 的 sed 命令不同
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac
        sed -i '' "s|image: ghcr.io/lintsinghua/deepaudit-frontend:latest|image: ${COMPOSE_IMAGE}|g" docker-compose.prod.yml
        sed -i '' "s|image: ghcr.nju.edu.cn/lintsinghua/deepaudit-frontend:latest|image: ${COMPOSE_IMAGE}|g" docker-compose.prod.cn.yml
    else
        # Linux
        sed -i "s|image: ghcr.io/lintsinghua/deepaudit-frontend:latest|image: ${COMPOSE_IMAGE}|g" docker-compose.prod.yml
        sed -i "s|image: ghcr.nju.edu.cn/lintsinghua/deepaudit-frontend:latest|image: ${COMPOSE_IMAGE}|g" docker-compose.prod.cn.yml
    fi
    
    echo -e "${GREEN}✓ 已自动更新 docker-compose.prod.yml${NC}"
    echo -e "${BLUE}备份文件: docker-compose.prod.yml.backup${NC}\n"
    
    echo -e "${YELLOW}接下来请执行:${NC}"
    echo -e "${GREEN}git add docker-compose.prod.yml docker-compose.prod.cn.yml${NC}"
    echo -e "${GREEN}git commit -m \"更新前端镜像路径为 /deepaudit/\"${NC}"
    echo -e "${GREEN}git push${NC}"
else
    echo -e "${BLUE}请手动更新配置文件${NC}"
fi

echo -e "\n${GREEN}🎉 完成！${NC}"
