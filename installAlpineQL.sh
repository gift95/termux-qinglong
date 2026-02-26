#!/bin/bash

# 定义颜色代码，用于美化输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 定义日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 定义检查命令执行状态的函数
check_status() {
    if [ $? -ne 0 ]; then
        log_error "$1 失败"
        exit 1
    else
        log_info "$1 成功"
    fi
}

# 确保脚本以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    log_error "请使用root用户运行此脚本"
    exit 1
fi

# 第1步：设置环境变量
log_info "开始第1步：设置环境变量"
set -x
if [ -f /etc/profile.d/ql_env.sh ]; then
    echo "文件 /etc/profile.d/ql_env.sh 已存在，跳过写入"
else
    echo -e "\nexport QL_DIR=/ql\nexport QL_BRANCH=master\nexport LANG=zh_CN.UTF-8\nexport TERMUX_APK_RELEASE=F-DROID\nexport VIRTUAL_ENV=/opt/venv
\nexport PATH=$VIRTUAL_ENV/bin:$PATH \nexport PNPM_HOME=/root/.local/share/pnpm\nexport PATH=$PNPM_HOME:$PATH \n export PATH=$PATH:/root/.local/share/pnpm:/root/.local/share/pnpm/global/5/node_modules \n export NODE_PATH=/usr/local/bin:/usr/local/pnpm-global/5/node_modules:/usr/local/lib/node_modules:/root/.local/share/pnpm/global/5/node_modules\nexport PYTHONUNBUFFERED=1" >>/etc/profile.d/ql_env.sh
    echo "环境变量已写入 /etc/profile.d/ql_env.sh"
fi
set +x
check_status "设置环境变量"

# 第2步：加载环境变量并配置DNS
log_info "开始第2步：加载环境变量并配置DNS"
source /etc/profile
echo -e "nameserver 119.29.29.29\n nameserver 8.8.8.8" >/etc/resolv.conf
check_status "加载环境变量并配置DNS"

# 第3步：更新软件源并安装依赖
log_info "开始第3步：更新软件源并安装依赖"
sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
check_status "更新软件源"

apk update -f
check_status "执行 apk update"

apk upgrade
check_status "执行 apk upgrade"

apk --no-cache add -f netcat-openbsd netcat-openbsd bash make nodejs npm coreutils moreutils git curl wget tzdata perl openssl nginx jq openssh python3 py3-pip
check_status "安装依赖包"

# 第4步：清理缓存并设置时区
log_info "开始第4步：清理缓存并设置时区"
rm -rf /var/cache/apk/*
check_status "清理APK缓存"

apk update
check_status "再次执行 apk update"

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" >/etc/timezone
check_status "设置时区"

# 第5步：配置npm并安装pnpm和pm2
log_info "开始第5步：配置npm并安装pnpm和pm2"
npm config set registry https://registry.npmmirror.com
check_status "配置npm镜像"

npm install -g pnpm@8.3.1
check_status "安装pnpm"

pnpm add -g pm2 tsx
check_status "安装pm2和tsx"

mkdir -p $QL_DIR
check_status "创建青龙目录"

# 第6步：克隆青龙仓库
log_info "开始第6步：克隆青龙仓库"
if [ ! -d "$QL_DIR/.git" ]; then
    git clone -b  $QL_BRANCH --depth=1 https://github.com/whyour/qinglong.git $QL_DIR
    check_status "克隆青龙仓库"
else
    log_warn "青龙仓库已存在，跳过克隆"
    cd $QL_DIR
    git pull
    check_status "更新青龙仓库"
fi




# 第7步：初始化青龙
log_info "开始第7步：初始化青龙"
cd $QL_DIR
cp -f .env.example .env
check_status "复制环境变量示例文件"

chmod 777 $QL_DIR/shell/*.sh
chmod 777 $QL_DIR/docker/*.sh
check_status "设置脚本权限"

pnpm install --prod
check_status "安装青龙依赖"

mkdir -p $QL_DIR/static
check_status "创建静态文件目录"

# 第8步：克隆静态文件仓库
log_info "开始第8步：克隆静态文件仓库"
if [ ! -d "$QL_DIR/static/.git" ]; then
    git clone -b  --depth=1 $QL_BRANCH https://github.com/whyour/qinglong-static.git $QL_DIR/static
    check_status "克隆静态文件仓库"
else
    log_warn "静态文件仓库已存在，跳过克隆"
    cd $QL_DIR/static
    git pull
    check_status "更新静态文件仓库"
fi

# 第9步：青龙必须在虚拟环境中运行，创建Python虚拟环境并激活
log_info "开始第9步：激活python虚拟环境"
python3 -m venv /opt/venv
echo 'source /opt/venv/bin/activate' >> /etc/profile
source /opt/venv/bin/activate
log_info "添加青龙面板python package目录到python虚拟环境的package中 使其可以加载页面安装的依赖"
location=$(pip show pip | grep Location | awk '{print $2}')
new_location=$(echo "$location" | sed 's|/opt/venv/|/ql/data/dep_cache/python3/|')
echo "$new_location" > $location/dep_cache.pth

# 第10步：设置青龙命令并启动
log_info "开始第10步：设置青龙命令并启动"
ln -s /ql/shell/task.sh /usr/bin/task 2>/dev/null
ln -s /ql/shell/update.sh /usr/bin/ql 2>/dev/null
ln -s /ql/docker/docker-entrypoint.sh /usr/bin/qinglong 2>/dev/null
check_status "设置青龙命令"

source /etc/profile
qinglong
check_status "启动青龙"

log_info "====================================="
log_info "所有步骤执行完毕，青龙已成功安装并启动！"

log_info "====================================="






