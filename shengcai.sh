#!/bin/bash

# 定义脚本版本          # 显示脚本版本
SCRIPT_VERSION="1.0.0" # echo -e "${BLUE}Script Version: $SCRIPT_VERSION${NC}"

# 定义颜色变量
RED='\033[0;31m' # echo -e "${RED}这是红色文本${NC}"
GREEN='\033[0;32m' # echo -e "${GREEN}这是绿色文本${NC}"
YELLOW='\033[1;33m' # echo -e "${YELLOW}这是黄色文本${NC}"
BLUE='\033[0;34m' # echo -e "${BLUE}这是蓝色文本${NC}"
NC='\033[0m' # No Color, 用于重置颜色

# 复制文件到 /usr/local/bin 并重命名为 k, 重定向所有输出到 /dev/null，以静默执行命令
cp ./shengcai.sh /usr/local/bin/k > /dev/null 2>&1

# install  安装函数。
install() {
    # 检查函数是否有参数传入，如果没有，则输出提示信息并返回错误状态码1
    if [ $# -eq 0 ]; then
        echo -e "${RED}未提供软件包参数!${NC}"
        return 1
    fi

    # 循环处理所有传入的参数，即要安装的软件包名称
    for package in "$@"; do
        # 检查软件包是否已经安装，如果没有安装则执行安装过程
        if ! command -v "$package" &>/dev/null; then
            # 根据不同的包管理器执行相应的安装命令
            if command -v dnf &>/dev/null; then
                echo -e "${BLUE}使用 dnf 安装 $package${NC}"
                dnf -y update && dnf install -y "$package"
            elif command -v yum &>/dev/null; then
                echo -e "${BLUE}使用 yum 安装 $package${NC}"
                yum -y update && yum -y install "$package"
            elif command -v apt &>/dev/null; then
                echo -e "${BLUE}使用 apt 安装 $package${NC}"
                apt update -y && apt install -y "$package"
            elif command -v apk &>/dev/null; then
                echo -e "${BLUE}使用 apk 安装 $package${NC}"
                apk update && apk add "$package"
            else
                # 如果未找到支持的包管理器，输出提示信息并返回错误状态码1
                echo -e "${RED}未知的包管理器!${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}$package 已经安装${NC}"
        fi
    done

    # 成功安装所有软件包后返回状态码0
    return 0
}

# ip_address 函数，用于获取IPv4和IPv6地址
ip_address() {
    # 获取IPv4地址并赋值给 ipv4_address 变量
    ipv4_address=$(curl -s ipv4.ip.sb)
    
    # 获取IPv6地址并赋值给 ipv6_address 变量，设置最大执行时间为1秒
    ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}

# install_dependency，用于安装依赖包
install_dependency() {
    # 清屏
    clear

    # 安装 wget、socat、unzip 和 tar 软件包
    install wget socat unzip tar
}

# remove 函数，用于卸载指定的软件包
remove() {
    # 检查函数是否有参数传入，如果没有，则输出提示信息并返回错误状态码1
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return 1
    fi

    # 循环处理所有传入的参数，即要卸载的软件包名称
    for package in "$@"; do
        # 根据不同的包管理器执行相应的卸载命令
        if command -v dnf &>/dev/null; then
            dnf remove -y "${package}*"
        elif command -v yum &>/dev/null; then
            yum remove -y "${package}*"
        elif command -v apt &>/dev/null; then
            apt purge -y "${package}*"
        elif command -v apk &>/dev/null; then
            apk del "${package}*"
        else
            # 如果未找到支持的包管理器，输出提示信息并返回错误状态码1
            echo "未知的包管理器!"
            return 1
        fi
    done

    # 成功卸载所有软件包后返回状态码0
    return 0
}

# break_end 函数，用于提示操作完成并等待用户按键继续
break_end() {
    # 输出提示信息，使用变量 ${GREEN} 和 ${NC} 设置颜色
    echo -e "${GREEN}操作完成${NC}"
    
    # 提示用户按任意键继续
    echo "按任意键继续..."
    
    # 读取用户输入的任意键，并在读取时不显示字符
    read -n 1 -s -r -p ""
    
    # 输出空行
    echo ""
    
    # 清屏
    clear
}

# check_port  函数用于检查指定端口（在这个例子中是 443 端口）的占用情况，并判断是否由 Nginx Docker 容器占用。如果端口被其他程序占用，会输出相应的警告信息并建议用户卸载占用端口的程序。以下是函数的详细解释和中文注释，以及一些优化建议。
check_port() {
    # 定义要检测的端口
    PORT=443

    # 检查端口占用情况
    result=$(ss -tulpn | grep ":$PORT")

    # 判断结果并输出相应信息
    if [ -n "$result" ]; then
        # 检查是否有 Nginx 容器占用端口
        is_nginx_container=$(docker ps --format '{{.Names}}' | grep 'nginx')

        # 判断是否是 Nginx 容器占用端口
        if [ -n "$is_nginx_container" ]; then
            echo ""
        else
            clear
            echo -e "${RED}端口 ${YELLOW}$PORT${RED} 已被占用，无法安装环境，卸载以下程序后重试！${NC}"
            echo "$result"
            break_end
            shengcaiteam
        fi
    else
        echo ""
    fi
}

# install_add_docker，用于安装 Docker 和 Docker Compose
install_add_docker() {
    if [ -f "/etc/alpine-release" ]; then
        # 如果是 Alpine Linux，则使用 apk 包管理器安装 Docker 和 Docker Compose
        apk update
        apk add docker docker-compose
        rc-update add docker default
        service docker start
    else
        # 否则使用官方的 Docker 安装脚本
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
    fi

    # 等待 2 秒以确保 Docker 服务启动
    sleep 2
}

# install_docker，用于检查并安装 Docker 环境
install_docker() {
    if ! command -v docker &>/dev/null; then
        install_add_docker
    else
        echo "Docker环境已经安装"
    fi
}

# docker_restart，用于重启 Docker 服务
docker_restart() {
    if [ -f "/etc/alpine-release" ]; then
        service docker restart
    else
        systemctl restart docker
    fi
}

# docker_ipv6_on，用于开启 Docker 的 IPv6 支持
docker_ipv6_on() {
    mkdir -p /etc/docker &>/dev/null

    cat > /etc/docker/daemon.json << EOF
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}
EOF

    docker_restart

    echo "Docker已开启v6访问"
}

# docker_ipv6_off，用于关闭 Docker 的 IPv6 支持
docker_ipv6_off() {
    rm -rf /etc/docker/daemon.json &>/dev/null

    docker_restart

    echo "Docker已关闭v6访问"
}

# iptables_open，用于设置 iptables 规则，开放所有端口
iptables_open() {
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    # 删除所有现有的 IPv4 规则，使得系统只按照默认策略（上面定义的 ACCEPT）来处理流量。
    iptables -F 

    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F
}

# shengcai 函数的作用是调用 k 命令后立即退出 shell 会话。这种功能通常用于在执行 k 命令后直接关闭当前会话的场景。
shengcai() {
    k
    exit
}

# add_swap 函数的目的是在 Linux 系统中重新创建和调整交换空间（swap）。该函数首先清理现有的 swap 分区和文件，然后根据指定的大小创建一个新的 swap 文件，并将其配置为系统启动时自动挂载。
add_swap() {
    # 获取当前系统中所有的 swap 分区
    swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

    # 遍历并删除所有的 swap 分区
    for partition in $swap_partitions; do
      swapoff "$partition"
      wipefs -a "$partition"  # 清除文件系统标识符
      mkswap -f "$partition"
    done

    # 确保 /swapfile 不再被使用
    swapoff /swapfile

    # 删除旧的 /swapfile
    rm -f /swapfile

    # 创建新的 swap 分区
    dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if [ -f /etc/alpine-release ]; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
        chmod +x /etc/local.d/swap.start
        rc-update add local
    else
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    echo -e "虚拟内存大小已调整为${YELLOW}${new_swap}${NC}MB"
}

# ldnmp_v 的函数， 它通过 Docker 获取并显示 Nginx、MySQL、PHP 和 Redis 的版本信息。
ldnmp_v() {
    # 获取 Nginx 版本
    nginx_version=$(docker exec nginx nginx -v 2>&1)
    nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
    echo -n -e "nginx : ${YELLOW}v$nginx_version${NC}"

    # 获取 MySQL 版本
    dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
    mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
    echo -n -e "            mysql : ${YELLOW}v$mysql_version${NC}"

    # 获取 PHP 版本
    php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
    echo -n -e "            php : ${YELLOW}v$php_version${NC}"

    # 获取 Redis 版本
    redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
    echo -e "            redis : ${YELLOW}v$redis_version${NC}"

    # 打印分隔线
    echo "------------------------"
    echo ""
}

# install_ldnmp 函数旨在自动化配置 LDNMP 环境，其中包括 L (Linux), D (Docker), N (Nginx), M (MySQL/MariaDB), 和 P (PHP)。这个脚本包括创建交换区、启动 Docker Compose、安装 PHP 扩展及配置，并通过进度条显示安装进度。
install_ldnmp() {

      new_swap=1024
      add_swap

      cd /home/web && docker compose up -d
      clear
      echo "正在配置LDNMP环境，请耐心稍等……"

      # 定义要执行的命令
      commands=(
          "docker exec nginx chmod -R 777 /var/www/html"
          "docker restart nginx > /dev/null 2>&1"

          "docker exec php sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories > /dev/null 2>&1"
          "docker exec php74 sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories > /dev/null 2>&1"

          "docker exec php apk update > /dev/null 2>&1"
          "docker exec php74 apk update > /dev/null 2>&1"

          # php安装包管理
          "curl -sL https://hub.gitmirror.com/https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions > /dev/null 2>&1"
          "docker exec php mkdir -p /usr/local/bin/ > /dev/null 2>&1"
          "docker exec php74 mkdir -p /usr/local/bin/ > /dev/null 2>&1"
          "docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/ > /dev/null 2>&1"
          "docker cp /usr/local/bin/install-php-extensions php74:/usr/local/bin/ > /dev/null 2>&1"
          "docker exec php chmod +x /usr/local/bin/install-php-extensions > /dev/null 2>&1"
          "docker exec php74 chmod +x /usr/local/bin/install-php-extensions > /dev/null 2>&1"

          # php安装扩展
          "docker exec php install-php-extensions mysqli > /dev/null 2>&1"
          "docker exec php install-php-extensions pdo_mysql > /dev/null 2>&1"
          "docker exec php install-php-extensions gd > /dev/null 2>&1"
          "docker exec php install-php-extensions intl > /dev/null 2>&1"
          "docker exec php install-php-extensions zip > /dev/null 2>&1"
          "docker exec php install-php-extensions exif > /dev/null 2>&1"
          "docker exec php install-php-extensions bcmath > /dev/null 2>&1"
          "docker exec php install-php-extensions opcache > /dev/null 2>&1"
          "docker exec php install-php-extensions imagick > /dev/null 2>&1"
          "docker exec php install-php-extensions redis > /dev/null 2>&1"

          # php配置参数
          "docker exec php sh -c 'echo \"upload_max_filesize=50M \" > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"post_max_size=50M \" > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"max_execution_time=1200\" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"max_input_time=600\" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1"

          # php重启
          "docker exec php chmod -R 777 /var/www/html"
          "docker restart php > /dev/null 2>&1"

          # php7.4安装扩展
          "docker exec php74 install-php-extensions mysqli > /dev/null 2>&1"
          "docker exec php74 install-php-extensions pdo_mysql > /dev/null 2>&1"
          "docker exec php74 install-php-extensions gd > /dev/null 2>&1"
          "docker exec php74 install-php-extensions intl > /dev/null 2>&1"
          "docker exec php74 install-php-extensions zip > /dev/null 2>&1"
          "docker exec php74 install-php-extensions exif > /dev/null 2>&1"
          "docker exec php74 install-php-extensions bcmath > /dev/null 2>&1"
          "docker exec php74 install-php-extensions opcache > /dev/null 2>&1"
          "docker exec php74 install-php-extensions imagick > /dev/null 2>&1"
          "docker exec php74 install-php-extensions redis > /dev/null 2>&1"

          # php7.4配置参数
          "docker exec php74 sh -c 'echo \"upload_max_filesize=50M \" > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"post_max_size=50M \" > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"max_execution_time=1200\" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"max_input_time=600\" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1"

          # php7.4重启
          "docker exec php74 chmod -R 777 /var/www/html"
          "docker restart php74 > /dev/null 2>&1"
      )

      total_commands=${#commands[@]}  # 计算总命令数

      for ((i = 0; i < total_commands; i++)); do
          command="${commands[i]}"
          eval $command  # 执行命令

          # 打印百分比和进度条
          percentage=$(( (i + 1) * 100 / total_commands ))
          completed=$(( percentage / 2 ))
          remaining=$(( 50 - completed ))
          progressBar="["
          for ((j = 0; j < completed; j++)); do
              progressBar+="#"
          done
          for ((j = 0; j < remaining; j++)); do
              progressBar+="."
          done
          progressBar+="]"
          echo -ne "\r[${GREEN}$percentage%${NC}] $progressBar"
      done

      echo  # 打印换行，以便输出不被覆盖

      clear
      echo "LDNMP环境安装完毕"
      echo "------------------------"
      ldnmp_v

}

# install_certbot 函数用于在不同的 Linux 发行版上安装 Certbot，并设置一个定时任务来自动续签 SSL/TLS 证书。
install_certbot() {

    if command -v yum &>/dev/null; then
        install epel-release certbot
    elif command -v apt &>/dev/null; then
        install snapd
        snap install core
        snap install --classic certbot
        rm /usr/bin/certbot
        ln -s /snap/bin/certbot /usr/bin/certbot
    else
        install certbot
    fi

    # 切换到一个一致的目录（例如，家目录）
    cd ~ || exit

    # 下载并使脚本可执行
    curl -O https://raw.gitmirror.com/shengcaiteam/shengcai.sh/main/auto_cert_renewal.sh
    chmod +x auto_cert_renewal.sh

    # 设置定时任务字符串
    cron_job="0 0 * * * ~/auto_cert_renewal.sh"

    # 检查是否存在相同的定时任务
    existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

    # 如果不存在，则添加定时任务
    if [ -z "$existing_cron" ]; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "续签任务已添加"
    else
        echo "续签任务已存在，无需添加"
    fi
}

# install_ssltls 函数的主要功能是通过 Certbot 续签或申请 SSL/TLS 证书。 
install_ssltls() {
    # 停止 Nginx 服务，以便 Certbot 可以使用端口 80 和 443
    docker stop nginx > /dev/null 2>&1
    
    # 打开防火墙规则，防止续签过程中被阻挡
    iptables_open

    # 切换到用户的主目录
    cd ~

    # 获取当前 Certbot 的版本号
    certbot_version=$(certbot --version 2>&1 | grep -oP "\d+\.\d+\.\d+")

    # 定义一个比较版本号的函数
    version_ge() {
        [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
    }

    # 检查 Certbot 的版本是否大于等于 1.10.0
    if version_ge "$certbot_version" "1.10.0"; then
        # 如果 Certbot 版本 >= 1.10.0，使用 ecdsa 密钥类型续签证书
        certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
    else
        # 如果 Certbot 版本 < 1.10.0，使用默认密钥类型续签证书
        certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal
    fi

    # 复制续签后的证书文件和私钥文件到指定目录
    cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem
    cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem

    # 重新启动 Nginx 服务
    docker start nginx > /dev/null 2>&1
}


# default_server_ssl  主要作用是为服务器生成一个自签名的 SSL/TLS 证书和密钥，用于加密通信。
default_server_ssl() {
    # 安装 OpenSSL
    install openssl
    
    # 生成自签名证书和私钥，默认使用 RSA 算法
    # 证书有效期为 5475 天（约 15 年），包含指定的主题信息
    # 使用 elliptic curve 加密算法生成密钥，并选择 prime256v1 曲线
    if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
        openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
    else
        # 如果系统没有 dnf 或 yum 命令，则生成 Ed25519 算法的私钥
        openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
        # 使用生成的 Ed25519 密钥创建自签名证书
        openssl req -x509 -key /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
    fi
}


# nginx_status 函数 主要作用是检查 Nginx 容器的状态，并在发现问题时执行一些清理和恢复操作。它是一个用于监控和管理 Nginx 容器的 Bash 函数。
nginx_status() {
    # 暂停 1 秒，以确保在检查之前的准备工作已完成
    sleep 1

    # Nginx 容器名称
    nginx_container_name="nginx"

    # 获取容器的状态
    container_status=$(docker inspect -f '{{.State.Status}}' "$nginx_container_name" 2>/dev/null)

    # 获取容器的重启次数
    container_restart_count=$(docker inspect -f '{{.RestartCount}}' "$nginx_container_name" 2>/dev/null)

    # 检查容器是否在运行，并且没有处于"Restarting"状态
    if [ "$container_status" == "running" ]; then
        # 如果容器运行中，不执行任何操作
        echo ""
    else
        # 如果容器不在运行，执行清理操作

        # 删除指定域名的 HTML 目录
        rm -r /home/web/html/$yuming >/dev/null 2>&1

        # 删除 Nginx 配置文件
        rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1

        # 删除域名的证书和密钥文件
        rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
        rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

        # 尝试重启 Nginx 容器
        docker restart nginx >/dev/null 2>&1

        # 从 docker-compose.yml 文件中提取 MySQL 根密码
        dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

        # 使用提取的密码，删除与指定域名相关的数据库
        docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $dbname;" 2> /dev/null

        # 输出错误消息，提示用户检查域名解析
        echo -e "${RED}检测到域名证书申请失败，请检测域名是否正确解析或更换域名重新尝试！${NC}"
    fi
}


# repeat_add_yuming 函数 主要用于检查指定域名是否已经被配置在 Nginx 服务器的配置文件中。如果该域名已经存在，则提示用户删除现有的站点配置；如果不存在，则确认域名可以使用。
repeat_add_yuming() {

    # 检查是否存在以域名命名的 Nginx 配置文件
    if [ -e "$config_file" ]; then
        # 如果配置文件存在，输出提示信息，表明该域名已被使用
        echo -e "${YELLOW}当前 ${yuming} 域名已被使用，请前往31站点管理，删除站点，再部署 ${webname} ！${NC}"
        
        # 执行 break_end 函数，通常用于终止或退出当前脚本执行
        break_end
        
        # 执行 shengcaiteam 函数，可能用于处理后续的清理或退出操作
        shengcaiteam
    else
        # 如果配置文件不存在，输出提示信息，表明该域名可用
        echo "当前 ${yuming} 域名可用"
    fi
}


# add_yuming 函数,主要作用是指导用户将域名解析到本机 IP，并验证域名的可用性。在设置和配置新的域名前，该函数确保域名正确解析并没有与现有配置冲突。
add_yuming() {
    # 获取当前系统的 IPv4 和 IPv6 地址
    ip_address

    # 提示用户将域名解析到本机 IP 地址
    # ${YELLOW} 和 ${NC} 是颜色控制变量，用于高亮显示 IP 地址
    echo -e "先将域名解析到本机IP: ${YELLOW}$ipv4_address  $ipv6_address${NC}"

    # 读取用户输入的域名
    read -p "请输入你解析的域名: " yuming

    # 调用 repeat_add_yuming 函数，检查域名是否已被使用
    repeat_add_yuming
}

# add_db 函数，主要作用是在 MySQL 数据库中创建一个与指定域名相关的数据库，并为指定的 MySQL 用户授予对该数据库的全部访问权限。该函数通过读取 Docker Compose 文件中的 MySQL 配置信息来实现这一过程
add_db() {
    # 将域名中的非字母数字字符替换为下划线，以生成数据库名称。
    dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
    # 将处理后的数据库名称赋值给变量 dbname。
    dbname="${dbname}"

    # 从 docker-compose.yml 文件中提取 MySQL root 密码。
    dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
    # 从 docker-compose.yml 文件中提取 MySQL 用户名。
    dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
    # 从 docker-compose.yml 文件中提取 MySQL 用户密码。
    dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
    
    # 在 MySQL 容器中执行命令，创建数据库并授予指定用户所有权限。
    docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}


# reverse_proxy 函数用于自动化配置 Nginx 反向代理。   这个函数通过下载一个模板配置文件，并根据输入的域名和后端服务器的 IP 地址及端口进行替换，然后重新启动 Nginx 以应用新的配置。
reverse_proxy() {
    # 获取本机 IP 地址
    ip_address

    # 下载反向代理配置文件并保存到指定路径
    wget -O /home/web/conf.d/$yuming.conf https://gitmirror.com/ShengCaiTeam/sh/raw/main/nginx/reverse-proxy.conf


    # 替换配置文件中的占位符 yuming.com 为实际的域名 $yuming
    sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
    
    # 替换配置文件中的占位符 0.0.0.0 为后端服务器的 IP 地址 $ipv4_address
    sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
    
    # 替换配置文件中的占位符 0000 为后端服务器的端口 $duankou
    sed -i "s/0000/$duankou/g" /home/web/conf.d/$yuming.conf
    
    # 重新启动 Nginx 容器以应用新的配置
    docker restart nginx
}


# restart_ldnmp 函数,主要作用是调整 Nginx 和 PHP 容器中文件目录的权限，并重新启动这些容器。               这样做的目的是确保 Web 服务器和 PHP 处理程序能够正确访问和处理指定目录中的文件。这在 LEMP（Linux, Nginx, MySQL, PHP）或 LNMP（Linux, Nginx, MySQL, PHP）堆栈中非常常见。
restart_ldnmp() {
  # 修改 Nginx 容器中文件目录的权限。
    docker exec nginx chmod -R 777 /var/www/html
    # 修改 PHP 容器中文件目录的权限。
    docker exec php chmod -R 777 /var/www/html
    # 修改 PHP 7.4 容器中文件目录的权限。
    docker exec php74 chmod -R 777 /var/www/html

    # 重启容器
    docker restart nginx
    docker restart php
    docker restart php74
}

# has_ipv4_has_ipv6 函数函数用于检查当前系统是否有 IPv4 和 IPv6 地址，并设置相应的布尔变量。   has_ipv4 和 has_ipv6。这些变量指示系统是否具备 IPv4 和 IPv6 网络连接。
has_ipv4_has_ipv6() {

    # 获取本机 IP 地址
    ip_address

    # 检查是否有 IPv4 地址
    if [ -z "$ipv4_address" ]; then
        has_ipv4=false
    else
        has_ipv4=true
    fi

    # 检查是否有 IPv6 地址
    if [ -z "$ipv6_address" ]; then
        has_ipv6=false
    else
        has_ipv6=true
    fi
}


 
# docker_app 函数提供了一个管理 Docker 应用程序的简化界面，允许用户检查应用程序的安装状态，更新、卸载或安装新的应用程序。       它通过检测系统的 IPv4 和 IPv6 地址，提供访问 Docker 容器的详细信息，并引导用户执行相关的管理操作。
docker_app() {
    # 检查系统的 IPv4 和 IPv6 地址
    has_ipv4_has_ipv6

    # 检查 Docker 容器是否存在
    if docker inspect "$docker_name" &>/dev/null; then
        clear
        echo "$docker_name 已安装，访问地址: "
        # 如果有 IPv4 地址，则显示 IPv4 访问地址
        if $has_ipv4; then
            echo "http:$ipv4_address:$docker_port"
        fi
        # 如果有 IPv6 地址，则显示 IPv6 访问地址
        if $has_ipv6; then
            echo "http:[$ipv6_address]:$docker_port"
        fi
        echo ""
        echo "应用操作"
        echo "------------------------"
        echo "1. 更新应用             2. 卸载应用"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1)
                clear
                # 更新应用
                docker rm -f "$docker_name"       # 删除现有的 Docker 容器
                docker rmi -f "$docker_img"       # 删除现有的 Docker 镜像
                $docker_rum                       # 重新运行应用程序的命令
                clear
                echo "$docker_name 已经安装完成"
                echo "------------------------"
                echo "您可以使用以下地址访问:"
                if $has_ipv4; then
                    echo "http:$ipv4_address:$docker_port"
                fi
                if $has_ipv6; then
                    echo "http:[$ipv6_address]:$docker_port"
                fi
                echo ""
                $docker_use
                $docker_passwd
                ;;
            2)
                clear
                # 卸载应用
                docker rm -f "$docker_name"           # 删除 Docker 容器
                docker rmi -f "$docker_img"           # 删除 Docker 镜像
                rm -rf "/home/docker/$docker_name"    # 删除相关的本地文件
                echo "应用已卸载"
                ;;
            0)
                # 返回上一级菜单
                ;;
            *)
                # 无效输入
                ;;
        esac
    else
        clear
        echo "安装提示"
        echo "$docker_describe"
        echo "$docker_url"
        echo ""
        read -p "确定安装吗？(Y/N): " choice
        case "$choice" in
            [Yy])
                clear
                install_docker                             # 安装 Docker 的函数
                $docker_rum                                # 运行应用程序的命令
                clear
                echo "$docker_name 已经安装完成"
                echo "------------------------"
                echo "您可以使用以下地址访问:"
                if $has_ipv4; then
                    echo "http:$ipv4_address:$docker_port"
                fi
                if $has_ipv6; then
                    echo "http:[$ipv6_address]:$docker_port"
                fi
                echo ""
                $docker_use
                $docker_passwd
                ;;
            [Nn])
                # 用户选择不安装
                ;;
            *)
                # 无效输入
                ;;
        esac
    fi
}


# cluster_python3 函数的主要功能是切换到指定的目录，下载一个 Python 脚本，并使用 Python 3 解释器运行该脚本。
cluster_python3() {
    # 切换到 cluster 目录
    cd ~/cluster/

    # 下载 Python 任务脚本
    curl -sS -O https://gitmirror.com/ShengCaiTeam/sh/raw/main/python-for-vps/cluster/$py_task

    # 使用 Python 3 解释器运行下载的 Python 脚本
    python3 ~/cluster/$py_task
}

# tmux_run 函数用于检查是否存在名为 $SESSION_NAME 的 tmux 会话，如果存在，则附加到该会话，如果不存在，则创建一个新的 tmux 会话。   这对于在远程服务器或本地环境中长期运行的任务非常有用，因为 tmux 会话可以在用户断开连接后继续运行。
tmux_run() {
    # 检查是否存在名为 $SESSION_NAME 的 tmux 会话
    tmux has-session -t $SESSION_NAME 2>/dev/null

    # $? 是一个特殊变量，保存上一个命令的退出状态
    if [ $? != 0 ]; then
      # 如果会话不存在，创建一个新会话
      tmux new -s $SESSION_NAME
    else
      # 如果会话存在，附加到该会话
      tmux attach-session -t $SESSION_NAME
    fi
}


# f2b_status 函数用于重启 fail2ban Docker 容器，并在容器重启后检查 fail2ban 的状态。      fail2ban 是一个用于保护服务器免受暴力破解攻击的安全工具，通过分析日志文件并禁止恶意 IP 来防止多次失败的登录尝试。这个函数通过重启 fail2ban 容器并获取其当前状态来确保 fail2ban 服务的正常运行和监控。
f2b_status() {
    # 重启 fail2ban 容器
    docker restart fail2ban

    # 等待 3 秒以确保容器重启完成
    sleep 3

    # 获取 fail2ban 的状态
    docker exec -it fail2ban fail2ban-client status
}


# f2b_status_xxx 函数,主要作用是获取 fail2ban 容器中特定服务（jail）的状态信息。fail2ban 是一个保护服务器免受暴力破解攻击的工具，通过监控日志文件并禁止有问题的 IP 地址来防止多次失败的登录尝试。这个函数允许用户查询 fail2ban 对指定服务的监控和封禁状态。
f2b_status_xxx() {
    # 获取指定服务的 fail2ban 状态
    docker exec -it fail2ban fail2ban-client status $xxx
}


# f2b_install_sshd 函数,主要作用是在 Docker 容器中安装并配置 fail2ban 服务，用于保护 SSH 服务免受暴力破解攻击。fail2ban 通过监控日志文件并自动禁止多次失败登录尝试的 IP 地址来增强系统的安全性。该函数不仅创建和运行 fail2ban 容器，还根据系统类型下载适当的配置文件以针对 SSH 进行特定的保护。
f2b_install_sshd() {
    # 运行 fail2ban Docker 容器
    docker run -d \
        --name=fail2ban \
        --net=host \
        --cap-add=NET_ADMIN \
        --cap-add=NET_RAW \
        -e PUID=1000 \
        -e PGID=1000 \
        -e TZ=Etc/UTC \
        -e VERBOSITY=-vv \
        -v /path/to/fail2ban/config:/config \
        -v /var/log:/var/log:ro \
        -v /home/web/log/nginx/:/remotelogs/nginx:ro \
        --restart unless-stopped \
        lscr.io/linuxserver/fail2ban:latest

    sleep 3  # 等待 3 秒

    # 根据系统类型下载相应的 fail2ban 配置文件
    if grep -q 'Alpine' /etc/issue; then
        cd /path/to/fail2ban/config/fail2ban/filter.d
        curl -sS -O https://raw.gitmirror.com/shengcaiteam/config/main/fail2ban/alpine-sshd.conf
        curl -sS -O https://raw.gitmirror.com/shengcaiteam/config/main/fail2ban/alpine-sshd-ddos.conf
        cd /path/to/fail2ban/config/fail2ban/jail.d/
        curl -sS -O https://raw.gitmirror.com/shengcaiteam/config/main/fail2ban/alpine-ssh.conf
    elif grep -qi 'CentOS' /etc/redhat-release; then
        cd /path/to/fail2ban/config/fail2ban/jail.d/
        curl -sS -O https://raw.gitmirror.com/shengcaiteam/config/main/fail2ban/centos-ssh.conf
    else
        install rsyslog
        systemctl start rsyslog
        systemctl enable rsyslog
        cd /path/to/fail2ban/config/fail2ban/jail.d/
        curl -sS -O https://raw.gitmirror.com/shengcaiteam/config/main/fail2ban/linux-ssh.conf
    fi
}

# f2b_sshd 函数,主要作用是根据系统的类型获取 fail2ban 针对 SSH 服务的状态。fail2ban 是一个安全工具，通过监控日志文件并自动禁止多次失败登录尝试的 IP 地址来保护服务器。该函数根据不同的 Linux 发行版，设置适当的 xxx 变量值并调用 f2b_status_xxx 函数来获取和显示指定服务（jail）的状态。
f2b_sshd() {
    if grep -q 'Alpine' /etc/issue; then  # 检查系统是否为 Alpine Linux
        xxx=alpine-sshd  # 如果是，则设置 xxx=alpine-sshd 并调用 f2b_status_xxx 函数
        f2b_status_xxx
    elif grep -qi 'CentOS' /etc/redhat-release; then  # 检查系统是否为 CentOS
        xxx=centos-sshd  # 如果是，则设置 xxx=centos-sshd 并调用 f2b_status_xxx 函数
        f2b_status_xxx
    else
        xxx=linux-sshd  # 设置 xxx=linux-sshd 并调用 f2b_status_xxx 函数
        f2b_status_xxx
    fi
}


# server_reboot 函数,主要作用是通过交互式提示，询问用户是否要重启服务器。如果用户确认重启，函数将执行系统重启命令；如果用户选择不重启，函数将取消操作。该函数是一个简单而有效的方式来安全地处理服务器的重启操作，确保用户确认重启操作以避免误操作。
server_reboot() {
    # 询问是否重启服务器
    read -p "$(echo -e "${YELLOW}现在重启服务器吗？(Y/N): ${NC}")" rboot

    case "$rboot" in
        [Yy])
            echo "已重启"
            reboot
            ;;
        [Nn])
            echo "已取消"
            ;;
        *)
            echo "无效的选择，请输入 Y 或 N。"
            ;;
    esac
}


# output_status 函数,主要作用是从 /proc/net/dev 文件中读取网络接口的总接收和发送字节数，并将这些数值格式化为可读的单位（如 KB、MB、GB）后输出。通过使用 awk 脚本，该函数能够汇总所有网络接口的接收和发送流量，并以易于理解的格式显示。
output_status() {
    # 获取网络接口的总接收和发送字节数，并格式化输出
    output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
        NR > 2 { rx_total += $2; tx_total += $10 }
        END {
            rx_units = "Bytes";
            tx_units = "Bytes";
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

            if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

            printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
        }' /proc/net/dev)
    echo "$output"
}

# ldnmp_install_status_one 函数,主要作用是检查 LDNMP 环境（Linux, Docker, Nginx, MySQL, PHP）中的 PHP 容器是否已经安装。如果发现 PHP 容器已经存在，函数会输出提示信息，表明环境已安装并引导用户更新 LDNMP 环境。否则，函数不会执行任何操作。这在环境管理和部署脚本中非常有用，可以避免重复安装和冲突。
ldnmp_install_status_one() {
    if docker inspect "php" &>/dev/null; then
        echo -e "${YELLOW}LDNMP环境已安装。无法再次安装。可以使用37. 更新LDNMP环境${NC}"
        break_end
        shengcaiteam
    else
        echo
    fi
}


# ldnmp_install_status 函数,主要作用是检查 LDNMP 环境（Linux, Docker, Nginx, MySQL, PHP）是否已经安装，并根据检查结果执行不同的操作
ldnmp_install_status() {
    if docker inspect "php" &>/dev/null; then
        echo "LDNMP环境已安装，开始部署 $webname"
    else
        echo -e "${YELLOW}LDNMP环境未安装，请先安装LDNMP环境，再部署网站${NC}"
        break_end
        shengcaiteam
    fi
}

# nginx_install_status 函数,主要作用是检查 Docker 环境中是否已经安装了 Nginx。如果 Nginx 容器存在，函数会提示开始部署指定的网站；如果 Nginx 容器不存在，函数会输出警告信息，提醒用户先安装 Nginx 环境，并停止当前操作。这在部署脚本中非常有用，可以确保 Nginx 服务器的存在和准备工作是完整的。
nginx_install_status() {
    if docker inspect "nginx" &>/dev/null; then
        echo "nginx环境已安装，开始部署 $webname"
    else
        echo -e "${YELLOW}nginx未安装，请先安装nginx环境，再部署网站${NC}"
        break_end
        shengcaiteam
    fi
}


# ldnmp_web_on 函数,主要作用是当 LDNMP 环境（Linux, Docker, Nginx, MySQL, PHP）中的网站部署完成时，清晰地向用户显示部署成功的信息，并提供网站的访问地址。
ldnmp_web_on() {
    clear
    echo "您的 $webname 搭建好了！"
    echo "https://$yuming"
    echo "------------------------"
    echo "$webname 安装信息如下: "
}

# nginx_web_on 函数,主要作用是在成功搭建基于 Nginx 的网站后，向用户显示网站部署成功的信息，并提供网站的访问地址。这个函数是部署脚本的一部分，用于在成功搭建网站后向用户反馈结果，增强用户体验。
nginx_web_on() {
    clear
    echo "您的 $webname 搭建好了！"
    echo "https://$yuming"
}

# install_panel 函数,主要作用是检查指定的面板工具是否已安装，并根据用户的输入选择相应的操作。如果面板已经安装，函数提供管理或卸载面板的选项；如果面板未安装，函数提供安装面板的选项并根据系统类型执行适当的安装命令。这在管理和部署面板工具时非常有用，可以确保系统有一个适当的环境来支持面板的安装和操作。
install_panel() {
    if $lujing ; then
        clear
        echo "$panelname 已安装，应用操作"
        echo ""
        echo "------------------------"
        echo "1. 管理$panelname          2. 卸载$panelname"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1)
                clear
                $gongneng1
                $gongneng1_1
                ;;
            2)
                clear
                $gongneng2
                $gongneng2_1
                $gongneng2_2
                ;;
            0)
                break  # 跳出循环，退出菜单
                ;;
            *)
                break  # 跳出循环，退出菜单
                ;;
        esac
    else
        clear
        echo "安装提示"
        echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装 $panelname！"
        echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
        echo "官网介绍: $panelurl "
        echo ""

        read -p "确定安装 $panelname 吗？(Y/N): " choice
        case "$choice" in
            [Yy])
                iptables_open
                install wget
                if grep -q 'Alpine' /etc/issue; then
                    $ubuntu_mingling
                    $ubuntu_mingling2
                elif grep -qi 'CentOS' /etc/redhat-release; then
                    $centos_mingling
                    $centos_mingling2
                elif grep -qi 'Ubuntu' /etc/os-release; then
                    $ubuntu_mingling
                    $ubuntu_mingling2
                elif grep -qi 'Debian' /etc/os-release; then
                    $ubuntu_mingling
                    $ubuntu_mingling2
                else
                    echo "Unsupported OS"
                fi
                ;;
            [Nn])
                ;;
            *)
                ;;
        esac
    fi
}


# current_timezone 函数,主要作用是检查系统的时区设置，并根据系统类型返回当前的时区信息。不同的 Linux 发行版可能使用不同的工具和方法来管理和显示时区信息，该函数通过检测系统类型（如 Alpine Linux 或其他常见 Linux 发行版），适配相应的命令来获取时区信息。
current_timezone() {
    if grep -q 'Alpine' /etc/issue; then
       date +"%Z %z"
    else
       timedatectl | grep "Time zone" | awk '{print $3}'
    fi
}

#  set_timedate 函数,主要作用是设置系统的时区。根据系统类型的不同（如 Alpine Linux 或其他常见 Linux 发行版），函数采取不同的方法来调整系统的时区配置。
set_timedate() {
    shiqu="$1"
    if grep -q 'Alpine' /etc/issue; then
        install tzdata
        cp /usr/share/zoneinfo/${shiqu} /etc/localtime
        hwclock --systohc
    else
        timedatectl set-timezone ${shiqu}
    fi
}

# linux_update 函数,主要作用是根据不同的 Linux 发行版，自动执行系统的更新和升级操作。这个函数识别当前系统是基于 Debian 的发行版、Red Hat 系列的发行版，还是 Alpine Linux，并执行相应的更新命令。
linux_update() {
    # 更新基于 Debian 的系统
    if [ -f "/etc/debian_version" ]; then
        apt update -y && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    fi

    # 更新基于 Red Hat 的系统
    if [ -f "/etc/redhat-release" ]; then
        yum -y update
    fi

    # 更新 Alpine Linux 系统
    if [ -f "/etc/alpine-release" ]; then
        apk update && apk upgrade
    fi
}

# linux_clean 函数,主要作用是清理和释放 Linux 系统中的不必要文件和包，优化系统空间。此函数特别关注 Debian 系列系统（如 Debian、Ubuntu），通过清理包缓存、旧内核文件和系统日志来减少磁盘空间的占用。
linux_clean() {
    clean_debian() {
        # 清理 Debian 系统
        apt autoremove --purge -y
        apt clean -y
        apt autoclean -y
        apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
        journalctl --rotate
        journalctl --vacuum-time=1s
        journalctl --vacuum-size=50M
        apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
    }

    clean_redhat() {
        # 清理 Red Hat 系统
        yum autoremove -y
        yum clean all
        journalctl --rotate
        journalctl --vacuum-time=1s
        journalctl --vacuum-size=50M
        yum remove $(rpm -q kernel | grep -v $(uname -r)) -y
    }

    clean_alpine() {
        # 清理 Alpine Linux 系统
        apk del --purge $(apk info --installed | awk '{print $1}' | grep -v $(apk info --available | awk '{print $1}'))
        apk autoremove
        apk cache clean
        rm -rf /var/log/*
        rm -rf /var/cache/apk/*
    }

    # 主脚本
    if [ -f "/etc/debian_version" ]; then
        # Debian 系统
        clean_debian
    elif [ -f "/etc/redhat-release" ]; then
        # Red Hat 系统
        clean_redhat
    elif [ -f "/etc/alpine-release" ]; then
        # Alpine Linux 系统
        clean_alpine
    fi
}

#bbr_on 函数,主要作用是启用 Google 的 BBR（Bottleneck Bandwidth and Round-trip propagation time）拥塞控制算法来优化服务器的网络性能。BBR 可以显著提高带宽利用率和减少延迟，是近年来广泛推荐的 TCP 拥塞控制算法之一。
bbr_on() {
    # 启用 BBR 拥塞控制算法
    cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p
}

# set_dns 函数,主要作用是根据系统是否支持 IPv6，设置或更新系统的 DNS 服务器地址。它会检查机器是否有 IPv6 地址，如果有，则在 /etc/resolv.conf 文件中添加相应的 IPv6 DNS 服务器地址。
set_dns() {
    # 检查机器是否有 IPv6 地址
    ipv6_available=0
    if [[ $(ip -6 addr | grep -c "inet6") -gt 0 ]]; then
        ipv6_available=1
    fi

    # 更新 /etc/resolv.conf 文件中的 DNS 地址
    echo "nameserver $dns1_ipv4" > /etc/resolv.conf
    echo "nameserver $dns2_ipv4" >> /etc/resolv.conf

    if [[ $ipv6_available -eq 1 ]]; then
        echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
        echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
    fi

    echo "DNS地址已更新"
    echo "------------------------"
    cat /etc/resolv.conf
    echo "------------------------"
}


#  restart_ssh 函数,主要作用是根据系统的包管理器，选择合适的命令来重启 SSH 服务。这在需要重新加载 SSH 配置文件或者在更新 SSH 服务后非常有用。
restart_ssh() {
    # 重启 SSH 服务
    if command -v dnf &>/dev/null; then
        systemctl restart sshd
    elif command -v yum &>/dev/null; then
        systemctl restart sshd
    elif command -v apt &>/dev/null; then
        service ssh restart
    elif command -v apk &>/dev/null; then
        service sshd restart
    else
        echo "未知的包管理器!"
        return 1
    fi
}


#  new_ssh_port 函数,主要作用是更改 SSH 服务的端口号。通过修改 /etc/ssh/sshd_config 文件中的 Port 配置项，函数可以将 SSH 服务从默认的端口（通常是 22）更改为用户指定的端口。这在安全配置中非常有用，可以减少暴露在默认端口上的 SSH 攻击风险。函数还包括重启 SSH 服务并清理相关配置文件，以确保更改生效。
new_ssh_port() {
    # 备份 SSH 配置文件
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # 启用 Port 配置项
    sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

    # 替换 SSH 配置文件中的端口号
    sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

    # 删除所有附加的 sshd_config 和 ssh_config 文件夹内容
    rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

    # 重启 SSH 服务
    restart_ssh
    echo "SSH 端口已修改为: $new_port"

    clear
    iptables_open
    remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
}


#  add_sshkey 函数,主要作用是自动生成一个新的 SSH 密钥对，将生成的公钥添加到 authorized_keys 文件中，以启用基于公钥的 SSH 登录。同时，该函数还会修改 SSH 配置文件以禁用密码登录，只允许使用公钥登录。这一过程增强了服务器的安全性，减少了通过密码攻击访问的风险。
add_sshkey() {
    # 生成 SSH 密钥对
    ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

    # 将公钥添加到 authorized_keys 文件
    cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys

    # 获取本机 IP 地址
    ip_address
    echo -e "私钥信息已生成，务必复制保存，可保存成 ${YELLOW}${ipv4_address}_ssh.key${NC} 文件，用于以后的SSH登录"

    echo "--------------------------------"
    cat ~/.ssh/sshkey
    echo "--------------------------------"

    # 修改 SSH 配置文件以启用公钥登录并禁用密码登录
    sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
           -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
           -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
           -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

    # 删除所有附加的 sshd_config 和 ssh_config 文件夹内容
    rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

    echo -e "${GREEN}ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${NC}"
}


# add_sshpasswd 函数,主要作用是设置 root 用户的密码，并修改 SSH 配置以允许 root 用户使用密码登录。这种功能可以在需要 root 用户通过密码远程访问系统时使用，但必须注意，允许 root 用户密码登录会增加系统的安全风险。因此，在启用这个功能时，确保有适当的安全措施。
add_sshpasswd() {
    # 设置 ROOT 用户密码
    echo "设置你的ROOT密码"
    passwd

    # 修改 SSH 配置文件，允许 ROOT 用户登录和密码认证
    sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

    # 删除所有附加的 sshd_config 和 ssh_config 文件夹内容
    rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

    # 重启 SSH 服务
    restart_ssh
    echo -e "${GREEN}ROOT登录设置完毕！${NC}"

    # 重启服务器
    server_reboot
}


# root_use 函数,主要作用是否具有 root 权限，并在不是 root 用户的情况下发出警告。这是为了确保只有 root 用户才能运行某些需要更高权限的操作，防止非特权用户执行潜在的危险或不安全的命令。
root_use() {
    clear
    # 检查是否以 ROOT 用户身份运行
    [ "$EUID" -ne 0 ] && echo -e "${YELLOW}请注意，该功能需要root用户才能运行！${NC}" && break_end && shengcaiteam
}

# 无限循环开始
while true; do
    clear
    # ... 在此处可以插入其他命令或逻辑 ...
    sleep 1  # 添加一个延迟以防止循环过于频繁地刷新屏幕
done


echo -e " .----------------.  .----------------.  .----------------.  .-----------------. .----------------.   .----------------.  .----------------.  .----------------. "
echo "| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | | .--------------. || .--------------. || .--------------. |"
echo "| |    _______   | || |  ____  ____  | || |  _________   | || | ____  _____  | || |    ______    | | | |     ______   | || |      __      | || |     _____    | |"
echo "| |   /  ___  |  | || | |_   ||   _| | || | |_   ___  |  | || ||_   \|_   _| | || |  .' ___  |   | | | |   .' ___  |  | || |     /  \     | || |    |_   _|   | |"
echo "| |  |  (__ \_|  | || |   | |__| |   | || |   | |_  \_|  | || |  |   \ | |   | || | / .'   \_|   | | | |  / .'   \_|  | || |    / /\ \    | || |      | |     | |"
echo "| |   '.___`-.   | || |   |  __  |   | || |   |  _|  _   | || |  | |\ \| |   | || | | |    ____  | | | |  | |         | || |   / ____ \   | || |      | |     | |"
echo "| |  |`\____) |  | || |  _| |  | |_  | || |  _| |___/ |  | || | _| |_\   |_  | || | \ `.___]  _| | | | |  \ `.___.'\  | || | _/ /    \ \_ | || |     _| |_    | |"
echo "| |  |_______.'  | || | |____||____| | || | |_________|  | || ||_____|\____| | || |  `._____.'   | | | |   `._____.'  | || ||____|  |____|| || |    |_____|   | |"
echo "| |              | || |              | || |              | || |              | || |              | | | |              | || |              | || |              | |"
echo "| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | | '--------------' || '--------------' || '--------------' |"
echo " '----------------'  '----------------'  '----------------'  '----------------'  '----------------'   '----------------'  '----------------'  '----------------' "
echo "                                                                                                                                                                 "
echo -e "Sheng Cai 一键脚本工具"
echo -e "Sheng Cai 一键脚本工具"
echo "------------------------"
echo "1. 系统信息查询"
echo "2. 系统更新"
echo "3. 系统清理"
echo "4. 常用工具 ▶"
echo "5. BBR管理 ▶"
echo "6. Docker管理 ▶ "
echo "7. WARP管理 ▶ "
echo "8. 测试脚本合集 ▶ "
echo "9. 甲骨文云脚本合集 ▶ "
echo -e "${YELLOW}10. LDNMP建站 ▶ ${NC}"
echo "11. 面板工具 ▶ "
echo "12. 我的工作区 ▶ "
echo "13. 系统工具 ▶ "
echo "14. VPS集群控制 ▶ "
echo "------------------------"
echo "p. 幻兽帕鲁开服脚本 ▶"
echo "------------------------"
echo "00. 脚本更新"
echo "------------------------"
echo "0. 退出脚本"
echo "------------------------"
read -p "请输入你的选择: " choice
