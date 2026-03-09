FROM node:18-alpine

WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm install --omit=dev

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

# 启动命令
CMD ["node", "app.js"]
