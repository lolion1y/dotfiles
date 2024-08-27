#!/bin/sh
# LOVE FROM ATRI

dir=$(cd $(dirname $0); pwd)
api="https://api.github.com/repos/wzfdgh/ClashRepo/releases/latest"
version=$(curl -sS "$api" | awk -F'-| ' '/body/ {print $5}')
# 获取脚本路径及最新版本

tobackup() {
if [ -f $dir/clash ]; then
  mv $dir/clash /tmp/clash.bak
  echo "已备份旧核心喵"
else
  echo "当前路径下未找到旧核心喵"
fi
}

torestore() {
if [ -f /tmp/clash.bak ]; then
  mv /tmp/clash.bak $dir/clash
  echo "核心备份已还原喵"
else
  echo "未找到备份核心喵"
fi
}

update() {
case $(uname -s) in
  Darwin*) os="darwin" ;;
  MINGW*|MSYS*|CYGWIN*) os="windows" ;;
  Linux*) case $(uname -o) in
            Android*) os="android" ;;
            *) os="linux" ;;
          esac ;;
  *) echo "不支持的操作系统 $(uname -a)"; exit 1 ;;
esac
# 获取操作系统

case $(uname -m) in
  mipsel_24kc) arch="mipsle-hardfloat" ;;
  i386|x86) arch="386" ;;
  amd64|x86_64) arch="amd64" ;;
  arm64|aarch64|armv8) arch="arm64" ;;
  armv7|armv7l) arch="armv7" ;;
  *) echo "不支持的架构 $(uname -a)"; exit 1 ;;
esac

if [ "$arch" = "amd64" ]; then
  flags=$(awk '/^flags/ {gsub(/flags.*:|^/," ");print  $0 ; exit}' /proc/cpuinfo)
  has_flags() {
    for flag; do
      case "$flags" in
        *" $flag "*) : ;;
        *) return 1 ;;
      esac
    done
  }
  determine_level() {
    level=0
    if has_flags lm cmov cx8 fpu fxsr mmx syscall sse2; then
    level=1; fi
    if has_flags cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3; then
    level=2; fi
    if has_flags avx avx2 bmi1 bmi2 f16c fma abm movbe xsave; then
    level=3; fi
    if has_flags avx512f avx512bw avx512cd avx512dq avx512vl; then
    level=4; fi
  }
  determine_level
  case "$level" in
    [34]) arch="amd64" ;;
    *) arch="amd64-compatible" ;;
  esac
fi
# 获取架构-mips未完全包括
#arch=
# 如需指定架构请取消注释,填上你需要的架构,并把下面的试运行删去

gh="https://raw.githubusercontent.com/wzfdgh/ClashRepo/release/clash.meta-$os-$arch"
gp="https://mirror.ghproxy.com/raw.githubusercontent.com/wzfdgh/ClashRepo/release/clash.meta-$os-$arch"
js="https://cdn.jsdelivr.net/gh/wzfdgh/ClashRepo@release/clash.meta-$os-$arch"
size=$(curl -sS $api | grep clash.meta-$os-$arch\" -B 4 | awk -F': |,' '/size/ {print $2}')
loc=$(curl -sS https://1.0.0.1/cdn-cgi/trace | awk -F'=' '/loc/ {print $2}')

if [ "$loc" = "CN" ]; then
  url="$gp"
else
  url="$gh"
fi
#url="$js"
echo "OS=$os Arch=$arch Version=$version Szie=$size"
# 显示系统与架构,核心版本,仓库文件大小

if command -v wget > /dev/null 2>&1; then
  wget -nv -O /tmp/clash "$url"
else
  curl -sSLo /tmp/clash --retry 10 "$url"
fi

filesize=$(stat -c %s /tmp/clash)

if [ "$size" = "$filesize" ]; then
  chmod 755 /tmp/clash
#  tobackup
#  mv /tmp/clash $dir/clash
#  echo -n "$version" > $dir/.clash-meta-version
#  echo 更新完成了喵
#  exit 0
# 如果指定架构,把上面语句取消注释,并将这里
  newver=$(/tmp/clash -v | awk -F'-| ' '/alpha/ {print $4}')
  if [ "$newver" = "$version" ]; then
    tobackup
    mv /tmp/clash $dir/clash
    echo -n "$version" > $dir/.clash-meta-version
    echo "更新完成了喵"
    exit 0
  else
    echo "更新失败了喵,核心版本不匹配或无法运行 newver=$newver"
    torestore
    exit 1
  fi
# 到这里的部分,删掉
else
  echo "更新失败了喵,核心文件大小校验失败 filesize=$filesize"
  torestore
  exit 1
fi
}

if [ -f $dir/.clash-meta-version ] && [ $(cat $dir/.clash-meta-version) = "$version" ]; then
  echo "没有更新喵,还是等等吧"
  exit 0
else
  update
fi
