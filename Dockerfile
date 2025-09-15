# ---------- 构建阶段 ----------
FROM node:18 AS build

# 设置工作目录
WORKDIR /app

# 复制依赖文件并安装依赖
COPY package*.json ./
COPY nx.json .
COPY tsconfig.base.json .
COPY lerna.json* . 2>/dev/null || true
COPY .npmrc* . 2>/dev/null || true

RUN npm install

# 复制剩余代码并构建
COPY . .
RUN npm run build:web


# ---------- 运行阶段 ----------
FROM nginx:alpine

# 删除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 写入 Hugging Face Spaces 适配的 Nginx 配置
RUN echo 'server { \
    listen 7860; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# 复制构建产物 (Nx 输出目录)
COPY --from=build /app/dist/apps/web /usr/share/nginx/html

# 暴露 Hugging Face 要求的 7860 端口
EXPOSE 7860

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
