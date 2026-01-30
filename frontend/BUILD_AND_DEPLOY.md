# DeepAudit 前端镜像构建和发布指南

## 📖 核心概念说明

### 1. Docker 镜像命名规则

```
[仓库地址/][用户名/]镜像名:标签
```

**示例：**
- `nginx:latest` - 官方镜像
- `lintsinghua/deepaudit-frontend:latest` - Docker Hub 上的个人镜像
- `registry.cn-hangzhou.aliyuncs.com/myname/deepaudit-frontend:latest` - 阿里云镜像

### 2. `your-username` 是什么？

`your-username` 是你的 **Docker Hub 用户名** 或 **镜像仓库命名空间**。

**Docker Hub 示例：**
- 注册地址：https://hub.docker.com/
- 假设你的用户名是 `zhangsan`
- 那么镜像就是：`zhangsan/deepaudit-frontend:latest`

**阿里云示例：**
- 注册地址：https://cr.console.aliyun.com/
- 假设你的命名空间是 `mycompany`，地域是杭州
- 那么镜像就是：`registry.cn-hangzhou.aliyuncs.com/mycompany/deepaudit-frontend:latest`

### 3. 镜像标签说明

- `latest` - 最新版本（默认）
- `v3.0.4` - 版本号
- `v3.0.4-deepaudit` - 版本号+特性说明

## 🚀 完整流程（三步走）

### 步骤 1️⃣：本地构建和测试

```bash
# 1. 进入前端目录
cd /Users/loogeek/Documents/work/数字海南/DeepAudit/frontend

# 2. 构建镜像（使用本地名称）
docker build -t deepaudit-frontend:test .

# 3. 本地测试
docker run -d --name test-frontend -p 3001:80 deepaudit-frontend:test

# 4. 访问测试
# 浏览器打开：http://localhost:3001/deepaudit/
# 或使用命令：
curl http://localhost:3001/deepaudit/

# 5. 查看日志（如果有问题）
docker logs test-frontend

# 6. 测试完成后清理
docker rm -f test-frontend
```

### 步骤 2️⃣：推送到镜像仓库

#### 选项 A：使用 Docker Hub（国际）

```bash
# 1. 登录 Docker Hub
docker login
# 输入你的用户名和密码

# 2. 给镜像打标签（将 zhangsan 替换为你的用户名）
docker tag deepaudit-frontend:test zhangsan/deepaudit-frontend:latest

# 3. 推送到 Docker Hub
docker push zhangsan/deepaudit-frontend:latest
```

#### 选项 B：使用阿里云（推荐，国内快）

```bash
# 1. 登录阿里云镜像服务
# 将 registry.cn-hangzhou.aliyuncs.com 替换为你的地域
# 将 mycompany 替换为你的命名空间
docker login registry.cn-hangzhou.aliyuncs.com
# 输入你的阿里云账号和密码

# 2. 给镜像打标签
docker tag deepaudit-frontend:test \
  registry.cn-hangzhou.aliyuncs.com/mycompany/deepaudit-frontend:latest

# 3. 推送到阿里云
docker push registry.cn-hangzhou.aliyuncs.com/mycompany/deepaudit-frontend:latest
```

### 步骤 3️⃣：更新 docker-compose 配置

编辑 `docker-compose.prod.yml` 的第 90 行：

```yaml
# 原来的（使用原作者的镜像）
frontend:
  image: ghcr.io/lintsinghua/deepaudit-frontend:latest

# 改成你的（Docker Hub）
frontend:
  image: zhangsan/deepaudit-frontend:latest

# 或改成你的（阿里云）
frontend:
  image: registry.cn-hangzhou.aliyuncs.com/mycompany/deepaudit-frontend:latest
```

### 步骤 4️⃣：提交到 GitHub

```bash
cd /Users/loogeek/Documents/work/数字海南/DeepAudit

# 查看修改
git status

# 提交修改
git add docker-compose.prod.yml docker-compose.prod.cn.yml
git commit -m "更新前端镜像路径为 /deepaudit/"
git push
```

## ✅ 验证

同事使用：

```bash
# 如果你提交到了 main 分支
curl -fsSL https://raw.githubusercontent.com/your-github-username/DeepAudit/main/docker-compose.prod.yml | docker compose -f - up -d

# 访问
open http://localhost:3000/deepaudit/
```

## 📋 常见问题

### Q1: 如何获取 Docker Hub 用户名？

1. 访问 https://hub.docker.com/
2. 注册或登录
3. 右上角显示的就是你的用户名

### Q2: 如何获取阿里云镜像仓库地址？

1. 访问 https://cr.console.aliyun.com/
2. 选择"个人实例" → "命名空间" → "创建命名空间"
3. 命名空间名称就是你的 `your-username`
4. 完整地址格式：`registry.cn-[地域].aliyuncs.com/[命名空间]`

### Q3: 构建很慢怎么办？

国内构建可能很慢，因为需要下载 npm 包。Dockerfile 已经配置了国内镜像源，耐心等待即可。

### Q4: 推送失败怎么办？

- Docker Hub：检查是否需要翻墙
- 阿里云：检查登录信息是否正确
- 通用：检查网络连接

### Q5: 同事拉取镜像很慢怎么办？

使用阿里云或配置 Docker 镜像加速器。

## 🎯 快速参考

```bash
# 构建
docker build -t deepaudit-frontend:test .

# 本地测试
docker run -d --name test -p 3001:80 deepaudit-frontend:test
curl http://localhost:3001/deepaudit/

# 打标签（Docker Hub）
docker tag deepaudit-frontend:test your-username/deepaudit-frontend:latest

# 打标签（阿里云）
docker tag deepaudit-frontend:test \
  registry.cn-hangzhou.aliyuncs.com/your-namespace/deepaudit-frontend:latest

# 推送
docker push your-username/deepaudit-frontend:latest

# 清理
docker rm -f test
docker rmi deepaudit-frontend:test
```

## 💡 提示

- 第一次构建会比较慢（10-20 分钟），后续会快很多
- 推送镜像大约需要 5-10 分钟（取决于网络）
- 建议使用阿里云，国内访问更快
- 镜像大小约 400-500MB
