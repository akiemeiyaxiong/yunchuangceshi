# Docker 网站部署实战指南

## 目录
- [概述](#概述)
- [部署方案选择](#部署方案选择)
- [方案一：Nginx 静态网站部署](#方案一nginx-静态网站部署)
- [方案二：Node.js 应用部署](#方案二nodejs-应用部署)
- [方案三：Python Flask 应用部署](#方案三python-flask-应用部署)
- [方案四：PHP 网站部署](#方案四php-网站部署)
- [方案五：多服务组合部署](#方案五多服务组合部署)
- [生产环境优化](#生产环境优化)
- [CI/CD 自动化部署](#cicd-自动化部署)
- [监控与日志](#监控与日志)
- [常见问题](#常见问题)

---

## 概述

本文档详细介绍使用 Docker 部署各类网站的实战方案，涵盖静态网站、动态应用、数据库集成等多种场景。所有方案均基于 Ubuntu 22.04 + Docker 26 环境。

### 为什么选择 Docker 部署网站？

| 优势 | 说明 |
|------|------|
| 环境一致性 | 开发、测试、生产环境完全一致 |
| 快速部署 | 秒级启动，分钟级扩展 |
| 资源隔离 | 服务间互不干扰，安全可靠 |
| 易于回滚 | 版本管理简单，故障快速恢复 |
| 弹性伸缩 | 根据流量自动扩展实例数量 |

---

## 部署方案选择

### 方案对比

| 方案 | 适用场景 | 复杂度 | 性能 |
|------|----------|--------|------|
| Nginx 静态网站 | 企业官网、文档站点 | 低 | 高 |
| Node.js 应用 | 现代 Web 应用、API 服务 | 中 | 高 |
| Python Flask | 中小型 Web 应用 | 中 | 中 |
| PHP 网站 | WordPress、传统网站 | 中 | 中 |
| 多服务组合 | 复杂业务系统 | 高 | 高 |

---

## 方案一：Nginx 静态网站部署

### 适用场景
- 企业官方网站
- 产品展示页面
- 技术文档站点
- 前端构建产物部署

### 目录结构
```
nginx-website/
├── docker-compose.yml
├── nginx/
│   └── default.conf
├── html/
│   └── index.html
└── logs/
```

### 1. 创建项目目录
```bash
mkdir -p ~/nginx-website/{nginx,html,logs}
cd ~/nginx-website
```

### 2. 编写 Nginx 配置文件
```bash
cat > nginx/default.conf << 'EOF'
server {
    listen       80;
    server_name  localhost;
    
    # 开启 gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1M;
        add_header Cache-Control "public, immutable";
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
```

### 3. 创建示例网页
```bash
cat > html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker 部署示例</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; }
        .badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 0.5rem 1rem;
            border-radius: 20px;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 网站部署成功！</h1>
        <p>这是使用 Docker + Nginx 部署的静态网站</p>
        <div class="badge">Docker 26 + Ubuntu 22.04</div>
    </div>
</body>
</html>
EOF
```

### 4. 编写 Docker Compose 配置
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx-website
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./logs:/var/log/nginx
    restart: unless-stopped
    networks:
      - web-network

networks:
  web-network:
    driver: bridge
EOF
```

### 5. 启动服务
```bash
# 启动容器
docker compose up -d

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 6. 验证部署
```bash
# 本地测试
curl http://localhost

# 查看容器日志
docker logs nginx-website
```

---

## 方案二：Node.js 应用部署

### 适用场景
- React/Vue/Angular 前端应用
- Express/Koa/Nest.js API 服务
- 实时应用（Socket.io）

### 目录结构
```
node-app/
├── docker-compose.yml
├── Dockerfile
├── .dockerignore
└── src/
    └── app.js
```

### 1. 创建示例应用
```bash
mkdir -p ~/node-app/src
cd ~/node-app

# 初始化项目
cat > package.json << 'EOF'
{
  "name": "docker-node-app",
  "version": "1.0.0",
  "description": "Dockerized Node.js Application",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0"
  }
}
EOF

# 创建应用代码
cat > src/app.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(helmet());
app.use(cors());
app.use(express.json());

// 健康检查
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// 主路由
app.get('/', (req, res) => {
    res.json({
        message: 'Node.js 应用运行中！',
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development'
    });
});

// API 路由
app.get('/api/users', (req, res) => {
    res.json([
        { id: 1, name: '张三' },
        { id: 2, name: '李四' },
        { id: 3, name: '王五' }
    ]);
});

// 错误处理
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: '服务器内部错误' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 服务器运行在端口 ${PORT}`);
});
EOF
```

### 2. 编写 Dockerfile
```bash
cat > Dockerfile << 'EOF'
# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 生产阶段
FROM node:18-alpine AS production

# 安全：创建非 root 用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# 从构建阶段复制依赖
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# 复制应用代码
COPY --chown=nodejs:nodejs . .

# 切换到非 root 用户
USER nodejs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# 启动命令
CMD ["npm", "start"]
EOF
```

### 3. 编写 .dockerignore
```bash
cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.vscode
.idea
EOF
```

### 4. 编写 Docker Compose 配置
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    container_name: node-app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    networks:
      - app-network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M

  # Nginx 反向代理
  nginx:
    image: nginx:alpine
    container_name: node-nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOF
```

### 5. 编写 Nginx 配置
```bash
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream node_app {
        server app:3000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://node_app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF
```

### 6. 启动服务
```bash
docker compose up -d --build
```

---

## 方案三：Python Flask 应用部署

### 适用场景
- 中小型 Web 应用
- 数据可视化平台
- RESTful API 服务

### 1. 创建项目结构
```bash
mkdir -p ~/flask-app
cd ~/flask-app
```

### 2. 编写应用代码
```bash
cat > app.py << 'EOF'
from flask import Flask, jsonify
from datetime import datetime
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'message': 'Flask 应用运行中！',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
EOF
```

### 3. 编写 requirements.txt
```bash
cat > requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
EOF
```

### 4. 编写 Dockerfile
```bash
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 暴露端口
EXPOSE 5000

# 使用 gunicorn 运行
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--timeout", "60", "app:app"]
EOF
```

### 5. 编写 Docker Compose 配置
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  flask:
    build: .
    container_name: flask-app
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - PORT=5000
    restart: unless-stopped
    networks:
      - flask-network

networks:
  flask-network:
    driver: bridge
EOF
```

### 6. 启动服务
```bash
docker compose up -d --build
```

---

## 方案四：PHP 网站部署

### 适用场景
- WordPress 网站
- Laravel 应用
- 传统 PHP 项目

### 1. 创建项目结构
```bash
mkdir -p ~/php-website/{php,nginx,mysql}
cd ~/php-website
```

### 2. 编写 Docker Compose 配置
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  php:
    image: php:8.2-fpm
    container_name: php-fpm
    volumes:
      - ./php:/var/www/html
    networks:
      - php-network

  nginx:
    image: nginx:alpine
    container_name: php-nginx
    ports:
      - "80:80"
    volumes:
      - ./php:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
    networks:
      - php-network

  mysql:
    image: mysql:8.0
    container_name: php-mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: website
      MYSQL_USER: webuser
      MYSQL_PASSWORD: webpass
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - php-network

volumes:
  mysql_data:

networks:
  php-network:
    driver: bridge
EOF
```

### 3. 编写 Nginx 配置
```bash
cat > nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
```

### 4. 创建示例 PHP 文件
```bash
cat > php/index.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PHP Docker 网站</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 10px; display: inline-block; }
    </style>
</head>
<body>
    <h1>🐘 PHP 网站部署成功！</h1>
    <div class="info">
        <p>PHP 版本: <?php echo phpversion(); ?></p>
        <p>服务器时间: <?php echo date('Y-m-d H:i:s'); ?></p>
    </div>
</body>
</html>
EOF
```

### 5. 启动服务
```bash
docker compose up -d
```

---

## 方案五：多服务组合部署

### 适用场景
- 微服务架构
- 全栈应用（前端 + 后端 + 数据库）
- 复杂业务系统

### 1. 项目结构
```
fullstack-app/
├── docker-compose.yml
├── frontend/
│   ├── Dockerfile
│   └── nginx.conf
├── backend/
│   ├── Dockerfile
│   └── app.py
├── database/
│   └── init.sql
└── redis/
```

### 2. 完整 Docker Compose 配置
```bash
mkdir -p ~/fullstack-app
cd ~/fullstack-app

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # 前端服务
  frontend:
    build: ./frontend
    container_name: frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network
    restart: unless-stopped

  # 后端 API 服务
  backend:
    build: ./backend
    container_name: backend
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/appdb
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=your-secret-key
    depends_on:
      - postgres
      - redis
    networks:
      - app-network
    restart: unless-stopped
    deploy:
      replicas: 2

  # PostgreSQL 数据库
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    restart: unless-stopped

  # Redis 缓存
  redis:
    image: redis:7-alpine
    container_name: redis
    volumes:
      - redis_data:/data
    networks:
      - app-network
    restart: unless-stopped
    command: redis-server --appendonly yes

  # 后台任务队列
  worker:
    build: ./backend
    container_name: worker
    command: celery -A tasks worker --loglevel=info
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/appdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    networks:
      - app-network
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
EOF
```

---

## 生产环境优化

### 1. 安全配置
```yaml
# docker-compose.production.yml
version: '3.8'

services:
  app:
    read_only: true  # 只读文件系统
    user: "1000:1000"  # 非 root 用户
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
```

### 2. 性能优化
```yaml
services:
  app:
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

### 3. 日志管理
```yaml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "production_status"
        env: "OS_VERSION"
```

---

## CI/CD 自动化部署

### GitHub Actions 工作流示例
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Container Registry
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        push: true
        tags: ${{ secrets.DOCKER_USERNAME }}/myapp:${{ github.sha }}
    
    - name: Deploy to server
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.SERVER_HOST }}
        username: ${{ secrets.SERVER_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        script: |
          cd /opt/myapp
          docker compose pull
          docker compose up -d
```

---

## 监控与日志

### 1. 使用 Prometheus + Grafana 监控
```yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
```

### 2. 日志收集
```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f app

# 查看最近 100 行日志
docker compose logs --tail=100 app
```

---

## 常见问题

### 问题 1：容器无法启动
```bash
# 查看容器日志
docker compose logs service-name

# 检查配置语法
docker compose config

# 手动运行调试
docker run --rm -it image-name /bin/sh
```

### 问题 2：数据库连接失败
```bash
# 检查网络连接
docker network ls
docker network inspect project_network

# 检查服务状态
docker compose ps

# 查看数据库日志
docker compose logs database
```

### 问题 3：性能问题
```bash
# 查看资源使用
docker stats

# 限制资源使用
docker update --memory=512m --cpus=1 container-name
```

### 问题 4：数据持久化
```bash
# 备份数据卷
docker run --rm -v project_data:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /data .

# 恢复数据卷
docker run --rm -v project_data:/data -v $(pwd):/backup alpine tar xzf /backup/backup.tar.gz -C /data
```

---

## 参考资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Nginx 官方文档](https://nginx.org/en/docs/)
- [Node.js Docker 最佳实践](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)
- [腾讯云容器服务](https://cloud.tencent.com/product/tke)

---

## 版本信息

| 组件 | 版本 |
|------|------|
| Docker Engine | 26.x |
| Docker Compose | 2.x |
| Nginx | 1.25.x |
| Node.js | 18.x |
| Python | 3.11.x |
| PHP | 8.2.x |

---

*文档生成时间：2025-03-05*
*适用环境：Ubuntu 22.04 LTS + Docker 26*
