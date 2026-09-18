#!/bin/sh
# LOVE FROM ATRI
# 1.4.1-260918

OWNER="lolion1y"
REPO="ci4core"
API="$(curl -sS "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest")"
VER="$(echo -E "${API}" | awk -F'"| ' '/^  "name"/ {print $7}')"
TMP="${TMP:-${TMPDIR:-${TEMP:-/tmp}}}"
# 获取最新版本

backup() {
if [ -f "$(pwd)/clash" ]; then
  mv "$(pwd)/clash" "${TMP}/clash.bak"
  echo "已备份旧核心喵"
else
  echo "当前路径下未找到旧核心喵"
fi
}

restore() {
if [ -f "${TMP}/clash.bak" ]; then
  mv "${TMP}/clash.bak" "$(pwd)/clash"
  echo "核心备份已还原喵"
else
  echo "未找到备份核心喵"
fi
}

update() {
case "$(uname -s)" in
  Darwin*) OS="darwin" ;;
  FreeBSD*) OS="freebsd" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  Linux*) case "$(uname -o)" in [aA]ndroid) OS="android" ;; *) OS="linux" ;; esac ;;
  *) echo "不支持的操作系统 $(uname -a)"; exit 1 ;;
esac
# 获取操作系统

case "$(uname -m)" in
  "mipsel_24kc") ARCH="mipsle-hardfloat" ;;
#  "mips"|"mips64") if [ $(printf 'I' | hexdump -o | awk '{print substr($2, 6, 1); exit}') -eq 1 ]; then ARCH="$(uname -m)le"; fi; ARCH=""${ARCH}"_softfloat" ;;
  "i386"|"i486"|"i686"|"i786"|"x86") ARCH="386" ;;
  "amd64"|"x86_64"|"x64"|"x86-64") ARCH="amd64" ;;
  "armv5"|"armv5l") ARCH="armv5" ;;
  "armv6"|"armv6l") ARCH="armv6" ;;
  "armv7"|"armv7l"|"armv8l") ARCH="armv7" ;;
  "arm64"|"aarch64"|"armv8") case "${OS}" in android) ARCH="arm64-v8";; *) ARCH="arm64";; esac ;;
  *) echo "不支持的架构 $(uname -a)"; exit 1 ;;
esac

if [ "${ARCH}" = "amd64" ]; then
  FLAGS="$(awk '/^flags/ {gsub(/flags.*:|^/," "); print $0; exit}' /proc/cpuinfo)"
  has_flags() {
    for FLAG; do
      case "${FLAGS}" in
        *" ${FLAG} "*) : ;;
        *) return 1 ;;
      esac
    done
  }
  determine_level() {
    LEVEL=0
    if has_flags lm cmov cx8 fpu fxsr mmx syscall sse2; then
    LEVEL=1; fi
    if has_flags cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3; then
    LEVEL=2; fi
    if has_flags avx avx2 bmi1 bmi2 f16c fma abm movbe xsave; then
    LEVEL=3; fi
    if has_flags avx512f avx512bw avx512cd avx512dq avx512vl; then
    LEVEL=4; fi
  }
  determine_level
  case "${LEVEL}" in
    [34]) ARCH="amd64-v3" ;;
    2) ARCH="amd64-v2" ;;
    *) ARCH="amd64-v1" ;;
  esac
fi
# 获取架构
#ARCH=
# 如需指定架构请取消注释,填上你需要的架构,并把下面的试运行删去
GH="https://github.com/${OWNER}/${REPO}/releases/download/latest/clash.meta-${OS}-${ARCH}"
GP="https://ghfast.top/https://github.com/${OWNER}/${REPO}/releases/download/latest/clash.meta-${OS}-${ARCH}"

LOC="$(curl -sS "https://speed.cloudflare.com/cdn-cgi/trace" | awk -F'=' '/loc/ {print $2}')"
if [ "${LOC}" = "CN" ]; then
  URL="${GP}"
else
  URL="${GH}"
fi

SIZE="$(echo -E "${API}" | grep -8 "/clash.meta-$OS-$ARCH\"" | awk -F': |,' '/size/ {print $2}')"

echo -e "OS=\033[33m${OS}\033[0m Arch=\033[33m${ARCH}\033[0m Ver=\033[33m${VER}\033[0m Size=\033[33m${SIZE}\033[0m\nURL=\033[33m${URL}\033[0m"
# 显示系统与架构,核心版本及文件大小

curl -#Lo "${TMP}/clash-${VER}" --retry 8 "${URL}"

LOCALSIZE="$(ls -l "${TMP}/clash-${VER}" | awk '{print $5}')"

if [ "${LOCALSIZE}" = "${SIZE}" ]; then
  chmod 755 "${TMP}/clash-${VER}"
#  backup
#  mv "${TMP}/clash-${VER}" "$(pwd)/clash"
#  echo -n "${VER}" > "$(pwd)/.clash-meta-version"
#  echo "更新完成了喵"
#  exit 0
# 如果指定架构,把上面语句取消注释,并将这里
  LOCALVER=$("${TMP}/clash-${VER}" -v | awk -F' ' '{print $3; exit}')
  if [ "${LOCALVER}" = "${VER}" ]; then
    backup
    mv "${TMP}/clash-${VER}" "$(pwd)/clash"
    echo -n "${VER}" > "$(pwd)/.clash-meta-version"
    echo "更新完成了喵"
    exit 0
  else
    echo "更新失败了喵,核心版本不匹配或无法运行 LocalVer=${LOCALVER}"
    restore
    exit 1
  fi
# 到这里删掉
else
  echo "更新失败了喵,核心文件大小校验不成功或无法下载 LocalSize=${LOCALSIZE}"
  restore
  exit 1
fi
}

if [ -f "$(pwd)/.clash-meta-version" ] && [ "$(cat $(pwd)/.clash-meta-version)" = "${VER}" ]; then
  echo "没有更新喵,还是等等吧"
  exit 0
else
  update
fi
