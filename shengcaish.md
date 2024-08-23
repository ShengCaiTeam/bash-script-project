Debian/Ubuntu 安装下载工具 curl
apt update -y && apt install -y curl

CentOS 安装下载工具 curl
yum update && yum install curl

官网版一键脚本
curl -sS -O https://shengcai.team/shengcai.sh && chmod +x shengcai.sh && ./shengcai.sh

GitHub 版一键脚本 部分小伙伴会遇到官网版出现大段乱码！就用 GitHub 版本吧！
curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/shengcai.sh && chmod +x shengcai.sh && ./shengcai.sh

脚本主界面
脚本全面支持 Ubuntu、Debian 和 Cent OS 系统

只要执行命令自动获取最新版本

docker 管理器
轻松安装管理你的 docker 容器，无需安装任何可视化面板。操作优雅直觉！

---

在一般的代码和脚本中，变量 yuming 通常表示域名。为了使代码更易于理解和维护，建议使用更具描述性的变量名称来代替 yuming。以下是几个建议：

domain_name:

描述性明确，直接表示变量是一个域名。
示例：

```bash
复制代码
domain_name="example.com"
```

site_domain:

适合在涉及多个站点或应用的环境中，表示当前操作的特定站点域名。
示例：

```bash
site_domain="example.com"
```

web_domain:

强调域名是用于 Web 服务的。
示例：

```bash
web_domain="example.com"
```

server_domain:

强调域名是用于服务器的，适合用于服务器配置相关的脚本。
示例：

```bash
server_domain="example.com"
```

cert_domain:

如果变量主要用于处理证书相关的操作，使用这种命名可以更明确其用途。
示例：

```bash
cert_domain="example.com"
```

---

# 定义颜色变量

RED='\033[0;31m' # echo -e "${RED}这是红色文本${NC}"
GREEN='\033[0;32m' # echo -e "${GREEN}这是绿色文本${NC}"
YELLOW='\033[1;33m' # echo -e "${YELLOW}这是黄色文本${NC}"
BLUE='\033[0;34m' # echo -e "${BLUE}这是蓝色文本${NC}"
NC='\033[0m' # No Color, 用于重置颜色

     _                                  _
    | |                                (_)

**\_| |** **\_ \_ ** ** \_ \_** ** \_ \_
/ **| '_ \ / _ \ '_ \ / _` |  / __/ _` | |
\__ \ | | | \_\_/ | | | (_| | | (_| (_| | |
|**_/_| |\_|\_**|_| |_|\_\_, | \_**\__,_|\_|
**/ |  
 |\_\_\_/

         __                                   _

**\_**/ /\_ **\_ \_\_** \_**\_ \_ **\_\_\_\***\* _(_)
/ **\_/ ** \/ \_ \/ ** \/ ** `/  / ___/ __ `/ /
(** ) / / / **/ / / / /_/ / / /\_\_/ /_/ / /  
/\_**_/_/ /\_/\_**/_/ /_/\_\_, / \_**/\__,_/\_/  
 /\_\_\*\*/

     _                                  _

**\_| |** **\_ \_ ** ** \_ \_** ** _(_)
/ **| '_ \ / _ \ '_ \ / _` |  / __/ _` | |
\__ \ | | | \_\_/ | | | (_| | | (_| (_| | |
|**_/_| |\_|\_**|_| |_|\_\_, | \_**\__,_|_|
|_**/

     _                                  _
    | |                                (_)

**\_| |** **\_ \_ ** ** \_ \_** ** \_ \_
/ **| '_ \ / _ \ '_ \ / _` |  / __/ _` | |
\__ \ | | | \_\_/ | | | (_| | | (_| (_| | |
|**_/_| |\_|\_**|_| |_|\_\_, | \_**\__,_|\_|
**/ |  
 |\_\_\_/
