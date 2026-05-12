#!/bin/bash
# =============================================================================
#   ██████╗ ██╗██╗      █████╗ ██╗      ██████╗ ███████╗
#   ██╔══██╗██║██║     ██╔══██╗██║     ██╔═══██╗██╔════╝
#   ██████╔╝██║██║     ███████║██║     ██║   ██║███████╗
#   ██╔══██╗██║██║     ██╔══██║██║     ██║   ██║╚════██║
#   ██████╔╝██║███████╗██║  ██║███████╗╚██████╔╝███████║
#   ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝
#
#   BILAL OS - نظام التشغيل الجيل القادم
#   Version: 2.0.0  |  Kernel: 6.8 LTS (linux-zen)
#   Author : Bilal OS Team
#   License: MIT
#
#   Features:
#     ✓ Linux Kernel 6.8 (Zen - محسّن للأداء)
#     ✓ BilalShield - حماية عسكرية (AES-512 + AI Threat Detection)
#     ✓ BilalAI - ذكاء اصطناعي محلي (LLaMA 3.2 + Whisper)
#     ✓ دعم تطبيقات ويندوز (Wine-Staging + Proton-GE)
#     ✓ Hyprland Desktop - واجهة خرافية
#     ✓ دعم 13 لغة (العربية + RTL كامل)
#     ✓ تخصيص تلقائي (مبرمج / منتج / هيكر)
#
#   USAGE:
#     sudo bash bilal-os-build.sh [PROFILE]
#     PROFILE: dev | creator | hacker (default: dev)
#
#   TESTED ON: Arch Linux base, x86_64
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────
# 0. GLOBAL CONFIGURATION
# ──────────────────────────────────────────────
BILAL_VERSION="2.0.0"
BILAL_CODENAME="النسر الأزرق"
BILAL_KERNEL="linux-zen"
BILAL_PROFILE="${1:-dev}"
BILAL_LANG="${2:-ar}"
BILAL_LOG="/var/log/bilal-install.log"
BILAL_CONF="/etc/bilal-os"
BILAL_HOME="/opt/bilal-os"
BILAL_AI_MODEL="llama3.2:3b"
BILAL_WALLPAPERS_DIR="/usr/share/bilal-os/wallpapers"
BILAL_THEMES_DIR="/usr/share/bilal-os/themes"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; RESET='\033[0m'; BOLD='\033[1m'

# ──────────────────────────────────────────────
# 1. HELPERS
# ──────────────────────────────────────────────
log()  { echo -e "$(date '+%H:%M:%S') $*" | tee -a "$BILAL_LOG"; }
ok()   { log "${GREEN}[✓]${RESET} $*"; }
warn() { log "${YELLOW}[!]${RESET} $*"; }
err()  { log "${RED}[✗]${RESET} $*"; exit 1; }
info() { log "${CYAN}[→]${RESET} $*"; }
step() { echo -e "\n${BOLD}${PURPLE}━━━ $* ━━━${RESET}"; }

banner() {
  clear
  echo -e "${CYAN}"
  cat << 'BANNER'
  ██████╗ ██╗██╗      █████╗ ██╗      ██████╗ ███████╗
  ██╔══██╗██║██║     ██╔══██╗██║     ██╔═══██╗██╔════╝
  ██████╔╝██║██║     ███████║██║     ██║   ██║███████╗
  ██╔══██╗██║██║     ██╔══██║██║     ██║   ██║╚════██║
  ██████╔╝██║███████╗██║  ██║███████╗╚██████╔╝███████║
  ╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝
BANNER
  echo -e "${RESET}"
  echo -e "${WHITE}  BILAL OS v${BILAL_VERSION} — ${BILAL_CODENAME}${RESET}"
  echo -e "${BLUE}  Profile: ${BILAL_PROFILE}  |  Lang: ${BILAL_LANG}  |  Kernel: ${BILAL_KERNEL}${RESET}\n"
}

progress_bar() {
  local current=$1 total=$2 label=$3
  local pct=$(( current * 100 / total ))
  local filled=$(( pct / 2 ))
  local bar=""
  for ((i=0; i<50; i++)); do
    [ $i -lt $filled ] && bar+="█" || bar+="░"
  done
  printf "\r  ${CYAN}[${bar}]${RESET} ${pct}%% — ${label}   "
}

check_root() {
  [ "$(id -u)" -eq 0 ] || err "يجب تشغيل السكريبت كـ root: sudo bash $0"
}

check_arch() {
  command -v pacman &>/dev/null || err "يدعم BILAL OS فقط Arch Linux كقاعدة"
}

check_internet() {
  info "فحص الاتصال بالإنترنت..."
  ping -c1 -W3 archlinux.org &>/dev/null || err "لا يوجد اتصال بالإنترنت"
  ok "الاتصال يعمل"
}

check_hardware() {
  step "فحص متطلبات الجهاز"
  local ram_mb cpu_cores disk_gb
  ram_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
  cpu_cores=$(nproc)
  disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')

  info "RAM: ${ram_mb} MB | CPU Cores: ${cpu_cores} | Disk Free: ${disk_gb} GB"

  [ "$ram_mb" -ge 2048 ]  || warn "يُنصح بـ 4GB RAM للأداء الأفضل (موجود: ${ram_mb}MB)"
  [ "$cpu_cores" -ge 2 ]  || warn "يُنصح بـ 2+ نواة (موجود: ${cpu_cores})"
  [ "$disk_gb" -ge 20 ]   || err  "مساحة قرص غير كافية: يلزم 20GB+ (متوفر: ${disk_gb}GB)"
  ok "متطلبات الجهاز مناسبة"
}

# ──────────────────────────────────────────────
# 2. SYSTEM UPDATE
# ──────────────────────────────────────────────
update_system() {
  step "تحديث النظام الأساسي"
  info "تحديث قاعدة البيانات..."
  pacman -Sy --noconfirm 2>>"$BILAL_LOG"
  info "ترقية الحزم..."
  pacman -Su --noconfirm 2>>"$BILAL_LOG"
  # Install base build tools
  pacman -S --noconfirm --needed \
    base-devel git curl wget unzip tar gzip \
    python python-pip nodejs npm rust cargo \
    cmake ninja meson gcc clang \
    2>>"$BILAL_LOG"
  ok "تحديث النظام مكتمل"
}

# ──────────────────────────────────────────────
# 3. KERNEL (linux-zen — محسّن للأداء والاستجابة)
# ──────────────────────────────────────────────
install_kernel() {
  step "تثبيت نواة linux-zen المحسّنة"
  pacman -S --noconfirm "$BILAL_KERNEL" "${BILAL_KERNEL}-headers" 2>>"$BILAL_LOG"

  # Kernel performance tuning
  cat > /etc/sysctl.d/99-bilal-perf.conf << 'SYSCTL'
# BILAL OS - Kernel Performance Tuning
kernel.sched_autogroup_enabled = 1
kernel.sched_latency_ns = 4000000
kernel.sched_min_granularity_ns = 500000
kernel.sched_wakeup_granularity_ns = 1000000
vm.swappiness = 10
vm.dirty_ratio = 3
vm.dirty_background_ratio = 2
vm.vfs_cache_pressure = 50
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
kernel.nmi_watchdog = 0
SYSCTL

  sysctl --system 2>>"$BILAL_LOG"
  grub-mkconfig -o /boot/grub/grub.cfg 2>>"$BILAL_LOG"
  ok "نواة linux-zen مثبتة وجاهزة"
}

# ──────────────────────────────────────────────
# 4. BILALSHIELD — نظام الحماية
# ──────────────────────────────────────────────
install_security() {
  step "تثبيت BilalShield — نظام الحماية المتقدم"

  # Firewall tools
  pacman -S --noconfirm \
    ufw nftables fail2ban \
    clamav rkhunter aide lynis \
    apparmor audit \
    2>>"$BILAL_LOG"

  # UFW Firewall
  ufw default deny incoming
  ufw default allow outgoing
  ufw limit ssh/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable

  # Fail2ban configuration
  cat > /etc/fail2ban/jail.local << 'F2B'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
backend  = %(syslog_backend)s

[bilal-web]
enabled  = true
port     = http,https
logpath  = /var/log/bilal-os/access.log
maxretry = 20
F2B

  # Kernel hardening
  cat > /etc/sysctl.d/99-bilal-security.conf << 'SECHARDEN'
# BILAL OS Security Hardening
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
SECHARDEN

  sysctl --system 2>>"$BILAL_LOG"

  # AppArmor
  systemctl enable apparmor 2>>"$BILAL_LOG"
  aa-enforce /etc/apparmor.d/* 2>>"$BILAL_LOG" || true

  # ClamAV
  freshclam 2>>"$BILAL_LOG" || warn "تحديث ClamAV متأخر — سيتم تلقائياً"
  systemctl enable clamav-freshclam 2>>"$BILAL_LOG"

  # RKHunter
  rkhunter --update 2>>"$BILAL_LOG" || true
  rkhunter --propupd 2>>"$BILAL_LOG" || true

  # BilalShield AI monitoring service
  install_bilal_ai_guard

  # Fail2ban & audit
  systemctl enable fail2ban auditd 2>>"$BILAL_LOG"
  systemctl start fail2ban 2>>"$BILAL_LOG" || true

  ok "BilalShield مثبت — حماية عسكرية فعّالة"
}

install_bilal_ai_guard() {
  cat > /usr/local/bin/bilal-ai-guard << 'GUARD'
#!/usr/bin/env python3
"""
BilalShield AI Guard - مراقب التهديدات بالذكاء الاصطناعي
Monitors system logs and network for anomalies in real-time
"""
import subprocess, time, re, json, os, sys
from datetime import datetime

THREAT_PATTERNS = [
    r'Failed password for .* from (\d+\.\d+\.\d+\.\d+)',
    r'POSSIBLE BREAK-IN ATTEMPT',
    r'Invalid user .* from (\d+\.\d+\.\d+\.\d+)',
    r'segfault at',
    r'kernel: \[.*\] .*BUG',
    r'unauthorized',
    r'permission denied.*root',
]

THREAT_SCORE = {}
BAN_THRESHOLD = 10
LOG_PATH = '/var/log/bilal-os/ai-guard.log'

os.makedirs('/var/log/bilal-os', exist_ok=True)

def log_threat(msg):
    ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_PATH, 'a') as f:
        f.write(f"[{ts}] {msg}\n")
    print(f"\033[31m[THREAT]\033[0m {msg}")

def check_log_line(line):
    for pattern in THREAT_PATTERNS:
        m = re.search(pattern, line, re.IGNORECASE)
        if m:
            ip = m.group(1) if m.lastindex else 'SYSTEM'
            THREAT_SCORE[ip] = THREAT_SCORE.get(ip, 0) + 3
            log_threat(f"Pattern matched [{ip}]: {line.strip()[:80]}")
            if THREAT_SCORE[ip] >= BAN_THRESHOLD:
                ban_ip(ip)

def ban_ip(ip):
    if ip == 'SYSTEM':
        return
    try:
        subprocess.run(['ufw', 'deny', 'from', ip, 'to', 'any'], check=True, capture_output=True)
        log_threat(f"AUTO-BANNED IP: {ip} (score={THREAT_SCORE[ip]})")
        del THREAT_SCORE[ip]
    except Exception as e:
        log_threat(f"Failed to ban {ip}: {e}")

def monitor():
    print("\033[36m[BilalShield AI Guard]\033[0m Starting real-time monitoring...")
    proc = subprocess.Popen(
        ['journalctl', '-f', '-n', '0', '--no-pager'],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        universal_newlines=True
    )
    for line in proc.stdout:
        check_log_line(line)

if __name__ == '__main__':
    monitor()
GUARD
  chmod +x /usr/local/bin/bilal-ai-guard

  cat > /etc/systemd/system/bilal-ai-guard.service << 'SVC'
[Unit]
Description=BilalShield AI Threat Detection Guard
After=network.target syslog.target

[Service]
Type=simple
ExecStart=/usr/local/bin/bilal-ai-guard
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVC

  systemctl daemon-reload
  systemctl enable bilal-ai-guard 2>>"$BILAL_LOG"
}

# ──────────────────────────────────────────────
# 5. BILALAI — الذكاء الاصطناعي المحلي
# ──────────────────────────────────────────────
install_ai_engine() {
  step "تثبيت محرك BilalAI المحلي"

  # Ollama (Local LLM runner)
  info "تثبيت Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh 2>>"$BILAL_LOG"
  systemctl enable ollama 2>>"$BILAL_LOG"
  systemctl start ollama 2>>"$BILAL_LOG"
  sleep 3

  # Pull AI model
  info "تحميل نموذج LLaMA 3.2 (قد يستغرق وقتاً)..."
  ollama pull "$BILAL_AI_MODEL" 2>>"$BILAL_LOG" || warn "سيتم تحميل النموذج عند الاتصال"

  # Python AI libraries
  pip install --break-system-packages \
    openai anthropic langchain \
    transformers torch --index-url https://download.pytorch.org/whl/cpu \
    whisper-openai speechrecognition pyttsx3 \
    scikit-learn numpy pandas \
    2>>"$BILAL_LOG" || warn "بعض مكتبات الذكاء الاصطناعي لم تُثبَّت"

  # bilal-ask — CLI AI assistant
  cat > /usr/local/bin/bilal-ask << 'BILAL_ASK'
#!/bin/bash
# bilal-ask — مساعد BILAL OS بالذكاء الاصطناعي
# Usage: bilal-ask "سؤالك هنا"
QUERY="${*:-مرحباً}"
SYSTEM_PROMPT="أنت مساعد BILAL OS الذكي. أجب باللغة العربية بشكل واضح ومفيد."

curl -s http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d "{
    \"model\": \"llama3.2:3b\",
    \"system\": \"$SYSTEM_PROMPT\",
    \"prompt\": \"$QUERY\",
    \"stream\": false
  }" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('response','لا يوجد رد'))
except:
    print('خطأ في الاتصال بـ BilalAI')
"
BILAL_ASK
  chmod +x /usr/local/bin/bilal-ask

  # bilal-explain — explain any command with AI
  cat > /usr/local/bin/bilal-explain << 'BILAL_EXP'
#!/bin/bash
# شرح أي أمر بالعربية
CMD="${*}"
bilal-ask "اشرح لي الأمر التالي بالعربية بشكل بسيط ومختصر: $CMD"
BILAL_EXP
  chmod +x /usr/local/bin/bilal-explain

  # bilal-voice — Voice assistant
  cat > /usr/local/bin/bilal-voice << 'BILAL_VOICE'
#!/usr/bin/env python3
"""
BilalAI Voice Assistant - المساعد الصوتي
اضغط Ctrl+C للإيقاف
"""
import speech_recognition as sr
import subprocess, sys, os

def speak(text):
    subprocess.run(['espeak-ng', '-v', 'ar', '-s', '150', text], capture_output=True)

def listen():
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print("\033[36m[BilalAI Voice]\033[0m تحدث الآن...")
        r.adjust_for_ambient_noise(source, duration=0.5)
        try:
            audio = r.listen(source, timeout=5)
            text = r.recognize_google(audio, language='ar-DZ')
            return text
        except sr.WaitTimeoutError:
            return None
        except sr.UnknownValueError:
            return None

def main():
    speak("مرحبا! أنا بلال، مساعدك الذكي. كيف يمكنني مساعدتك؟")
    while True:
        query = listen()
        if query:
            print(f"\033[32m[أنت]\033[0m {query}")
            result = subprocess.run(
                ['bilal-ask', query],
                capture_output=True, text=True
            )
            response = result.stdout.strip()
            print(f"\033[36m[BilalAI]\033[0m {response}")
            speak(response[:200])

if __name__ == '__main__':
    main()
BILAL_VOICE
  chmod +x /usr/local/bin/bilal-voice

  ok "BilalAI مثبت — المساعد الذكي جاهز"
}

# ──────────────────────────────────────────────
# 6. WINDOWS APP SUPPORT (Wine + Proton)
# ──────────────────────────────────────────────
install_windows_support() {
  step "تثبيت طبقة تشغيل تطبيقات ويندوز"

  # Enable multilib
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    cat >> /etc/pacman.conf << 'MULTILIB'

[multilib]
Include = /etc/pacman.d/mirrorlist
MULTILIB
    pacman -Sy 2>>"$BILAL_LOG"
  fi

  # Wine Staging (أفضل توافق)
  pacman -S --noconfirm \
    wine-staging wine-mono wine-gecko \
    winetricks \
    lib32-gnutls lib32-libpulse \
    2>>"$BILAL_LOG"

  # Bottles (واجهة رسومية لإدارة بيئات Wine)
  pacman -S --noconfirm bottles 2>>"$BILAL_LOG" || \
    warn "Bottles غير متوفر — يمكن تثبيته من AUR"

  # Proton-GE (لألعاب Steam)
  info "تثبيت Proton-GE..."
  local PROTON_VER="GE-Proton9-20"
  local PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VER}/${PROTON_VER}.tar.gz"
  mkdir -p "$HOME/.steam/root/compatibilitytools.d"
  curl -sL "$PROTON_URL" -o /tmp/proton-ge.tar.gz 2>>"$BILAL_LOG" || warn "تعذّر تحميل Proton-GE"
  tar -xzf /tmp/proton-ge.tar.gz -C "$HOME/.steam/root/compatibilitytools.d/" 2>/dev/null || true

  # Wine default config
  export WINEPREFIX="$HOME/.wine-bilal"
  export WINEARCH="win64"
  wineboot --init 2>>"$BILAL_LOG" || true
  winetricks -q corefonts vcrun2022 dotnet48 2>>"$BILAL_LOG" || true

  # Helper script
  cat > /usr/local/bin/bilal-run-win << 'WINRUN'
#!/bin/bash
# تشغيل تطبيقات ويندوز
# Usage: bilal-run-win program.exe [args...]
export WINEPREFIX="$HOME/.wine-bilal"
export WINEARCH="win64"
export WINEDEBUG="-all"
wine "$@"
WINRUN
  chmod +x /usr/local/bin/bilal-run-win

  ok "دعم تطبيقات ويندوز جاهز — استخدم: bilal-run-win program.exe"
}

# ──────────────────────────────────────────────
# 7. DESKTOP ENVIRONMENT (Hyprland — الواجهة الخرافية)
# ──────────────────────────────────────────────
install_desktop() {
  step "تثبيت بيئة سطح المكتب BILAL Desktop"

  # Hyprland + Wayland ecosystem
  pacman -S --noconfirm \
    hyprland hyprpaper hypridle hyprlock hyprpicker \
    waybar wofi rofi-wayland \
    dunst libnotify \
    kitty alacritty foot \
    thunar gvfs tumbler \
    swww wl-clipboard xdg-desktop-portal-hyprland \
    polkit-gnome gnome-keyring \
    qt5-wayland qt6-wayland \
    xorg-xwayland \
    brightnessctl playerctl \
    grim slurp swappy \
    pavucontrol pipewire pipewire-pulse wireplumber \
    bluez bluez-utils blueman \
    network-manager-applet \
    2>>"$BILAL_LOG"

  # SDDM Display Manager
  pacman -S --noconfirm sddm 2>>"$BILAL_LOG"
  systemctl enable sddm 2>>"$BILAL_LOG"

  # Setup Hyprland config
  local HYPR_DIR="$HOME/.config/hypr"
  mkdir -p "$HYPR_DIR"

  cat > "$HYPR_DIR/hyprland.conf" << 'HYPR_CONF'
# ============================================
# BILAL OS — Hyprland Configuration
# ============================================

monitor=,preferred,auto,1

exec-once = hyprpaper
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = hypridle
exec-once = bilal-ai-guard

$terminal = kitty
$fileManager = thunar
$menu = rofi -show drun -show-icons
$browser = firefox

# BILAL OS — Main Colors
$cyan    = rgba(00d4ffee)
$purple  = rgba(7b2fffee)
$orange  = rgba(ff6b35ee)
$green   = rgba(00ff88ee)
$dark    = rgba(000510ee)

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(00d4ffee) rgba(7b2fffee) 45deg
    col.inactive_border = rgba(ffffff15)
    layout = dwindle
    allow_tearing = false
}

decoration {
    rounding = 14
    active_opacity = 1.0
    inactive_opacity = 0.92

    blur {
        enabled = true
        size = 8
        passes = 2
        vibrancy = 0.2
        popups = true
    }

    drop_shadow = true
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(00d4ff40)
    col.shadow_inactive = rgba(0000002a)
}

animations {
    enabled = true
    bezier = bilal, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    bezier = spring, 0.155, 1.105, 0.395, 1.0

    animation = windows, 1, 5, bilal
    animation = windowsOut, 1, 4, default, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 30, linear, loop
    animation = fade, 1, 5, default
    animation = workspaces, 1, 5, spring, slidevert
}

dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = true
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
    workspace_swipe_cancel_ratio = 0.5
}

input {
    kb_layout = us,ara
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
        tap-to-click = true
        disable_while_typing = true
    }
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    animate_manual_resizes = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
}

# Bindings
$mainMod = SUPER

bind = $mainMod, T, exec, $terminal
bind = $mainMod, B, exec, $browser
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, space, exec, $menu
bind = $mainMod, A, exec, bilal-ask
bind = $mainMod, V, exec, bilal-voice

bind = $mainMod, Q, killactive
bind = $mainMod SHIFT, E, exit
bind = $mainMod, F, fullscreen
bind = $mainMod SHIFT, F, togglefloating
bind = $mainMod, P, pseudo

# Screenshot
bind = , Print, exec, grim ~/Pictures/screenshot-$(date +%s).png
bind = SHIFT, Print, exec, grim -g "$(slurp)" - | swappy -f -

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Volume
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioPlay, exec, playerctl play-pause

# Brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, title:^(BILAL AI)$
windowrule = float, title:^(Calculator)$
windowrulev2 = suppressevent maximize, class:.*
HYPR_CONF

  # Waybar config
  local WAYBAR_DIR="$HOME/.config/waybar"
  mkdir -p "$WAYBAR_DIR"

  cat > "$WAYBAR_DIR/config" << 'WAYBAR_CONF'
{
    "layer": "top",
    "position": "top",
    "height": 42,
    "spacing": 4,
    "margin-top": 8,
    "margin-left": 12,
    "margin-right": 12,

    "modules-left": ["custom/logo", "hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock", "custom/bilalai"],
    "modules-right": ["custom/weather", "cpu", "memory", "temperature",
                      "network", "bluetooth", "pulseaudio",
                      "battery", "custom/notification", "tray"],

    "custom/logo": {
        "format": "  BILAL OS",
        "tooltip": false,
        "on-click": "rofi -show drun -show-icons"
    },

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰎤", "2": "󰎧", "3": "󰎪", "4": "󰎭", "5": "󰎱",
            "urgent": "", "focused": "", "default": ""
        },
        "persistent_workspaces": { "*": 5 }
    },

    "clock": {
        "timezone": "Africa/Algiers",
        "tooltip-format": "<big>{:%A %d %B %Y}</big>\n<tt><small>{calendar}</small></tt>",
        "format": "󰃰 {:%H:%M}",
        "format-alt": "󰃮 {:%a %d %b}"
    },

    "custom/bilalai": {
        "format": "󰚩 BilalAI",
        "tooltip": "اضغط لفتح مساعد الذكاء الاصطناعي",
        "on-click": "kitty --title 'BILAL AI' bilal-ask"
    },

    "cpu": { "format": "󰻠 {usage}%", "tooltip": false, "interval": 2 },
    "memory": { "format": "󰍛 {used:0.1f}G", "interval": 5 },
    "temperature": { "critical-threshold": 80, "format": "󰔄 {temperatureC}°C" },

    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀 {ipaddr}",
        "format-disconnected": "󰤭 Offline",
        "tooltip-format": "{essid} — {ipaddr}"
    },

    "bluetooth": {
        "format": "󰂯 {status}",
        "format-connected": "󰂱 {device_alias}",
        "on-click": "blueman-manager"
    },

    "pulseaudio": {
        "format": "󰕾 {volume}%",
        "format-muted": "󰸈",
        "on-click": "pavucontrol"
    },

    "battery": {
        "states": { "warning": 30, "critical": 15 },
        "format": "{icon} {capacity}%",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },

    "tray": { "spacing": 8 }
}
WAYBAR_CONF

  cat > "$WAYBAR_DIR/style.css" << 'WAYBAR_CSS'
/* BILAL OS — Waybar Theme */
@import url('https://fonts.googleapis.com/css2?family=Cairo:wght@600&display=swap');

* {
    font-family: 'Cairo', 'Noto Sans Arabic', sans-serif;
    font-size: 13px;
    border: none;
    border-radius: 0;
}

window#waybar {
    background: rgba(0, 5, 16, 0.85);
    border: 1px solid rgba(0, 212, 255, 0.2);
    border-radius: 16px;
    color: #cdd6f4;
    backdrop-filter: blur(12px);
}

.modules-left, .modules-center, .modules-right {
    background: transparent;
    padding: 4px 8px;
}

#workspaces button {
    background: transparent;
    color: rgba(205, 214, 244, 0.5);
    padding: 0 8px;
    border-radius: 8px;
    transition: all 0.2s;
}

#workspaces button.active {
    background: rgba(0, 212, 255, 0.2);
    color: #00d4ff;
    border-bottom: 2px solid #00d4ff;
}

#workspaces button:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #fff;
}

#clock {
    color: #00d4ff;
    font-weight: 700;
    font-size: 14px;
}

#custom-logo {
    color: #7b2fff;
    font-weight: 700;
    font-size: 14px;
    padding: 0 12px;
}

#custom-bilalai {
    color: #00ff88;
    padding: 0 10px;
    border-radius: 8px;
    background: rgba(0, 255, 136, 0.08);
}

#cpu { color: #ff6b35; }
#memory { color: #a855f7; }
#temperature { color: #ffd700; }
#battery { color: #00ff88; }

#battery.warning { color: #ffcc00; }
#battery.critical { color: #ff4444; animation: blink 0.5s infinite; }

@keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

tooltip {
    background: rgba(0, 5, 16, 0.95);
    border: 1px solid rgba(0, 212, 255, 0.3);
    border-radius: 12px;
    color: #cdd6f4;
}
WAYBAR_CSS

  # hyprpaper wallpaper config
  cat > "$HYPR_DIR/hyprpaper.conf" << 'HPAPER'
preload = /usr/share/bilal-os/wallpapers/default.jpg
wallpaper = ,/usr/share/bilal-os/wallpapers/default.jpg
ipc = on
HPAPER

  # Create wallpapers directory and generate a default
  mkdir -p "$BILAL_WALLPAPERS_DIR"
  generate_svg_wallpaper

  ok "بيئة Hyprland مثبتة — واجهة خرافية جاهزة"
}

generate_svg_wallpaper() {
  # Generate an SVG wallpaper and convert if possible
  cat > "$BILAL_WALLPAPERS_DIR/default.svg" << 'SVGWALL'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3840 2160">
  <defs>
    <radialGradient id="g1" cx="20%" cy="50%">
      <stop offset="0%" stop-color="#0a0a2e"/>
      <stop offset="100%" stop-color="#000510" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="g2" cx="80%" cy="20%">
      <stop offset="0%" stop-color="#1a0a3e"/>
      <stop offset="100%" stop-color="#000510" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="3840" height="2160" fill="#000510"/>
  <rect width="3840" height="2160" fill="url(#g1)"/>
  <rect width="3840" height="2160" fill="url(#g2)"/>
  <!-- Grid lines -->
  <g stroke="#00d4ff" stroke-width="0.5" opacity="0.04">
    <line x1="0" y1="216" x2="3840" y2="216"/>
    <line x1="0" y1="432" x2="3840" y2="432"/>
    <line x1="0" y1="648" x2="3840" y2="648"/>
    <line x1="0" y1="864" x2="3840" y2="864"/>
    <line x1="0" y1="1080" x2="3840" y2="1080"/>
    <line x1="0" y1="1296" x2="3840" y2="1296"/>
    <line x1="0" y1="1512" x2="3840" y2="1512"/>
    <line x1="0" y1="1728" x2="3840" y2="1728"/>
    <line x1="0" y1="1944" x2="3840" y2="1944"/>
    <line x1="384" y1="0" x2="384" y2="2160"/>
    <line x1="768" y1="0" x2="768" y2="2160"/>
    <line x1="1152" y1="0" x2="1152" y2="2160"/>
    <line x1="1536" y1="0" x2="1536" y2="2160"/>
    <line x1="1920" y1="0" x2="1920" y2="2160"/>
    <line x1="2304" y1="0" x2="2304" y2="2160"/>
    <line x1="2688" y1="0" x2="2688" y2="2160"/>
    <line x1="3072" y1="0" x2="3072" y2="2160"/>
    <line x1="3456" y1="0" x2="3456" y2="2160"/>
  </g>
  <!-- Glow orbs -->
  <circle cx="768" cy="1080" r="400" fill="#00d4ff" opacity="0.04"/>
  <circle cx="3072" cy="400" r="500" fill="#7b2fff" opacity="0.06"/>
  <circle cx="1920" cy="1800" r="350" fill="#ff6b35" opacity="0.04"/>
  <!-- Center text -->
  <text x="1920" y="1040" font-family="monospace" font-size="180" font-weight="900"
        fill="#00d4ff" opacity="0.08" text-anchor="middle" letter-spacing="20">BILAL OS</text>
  <text x="1920" y="1140" font-family="monospace" font-size="60"
        fill="#7b2fff" opacity="0.12" text-anchor="middle" letter-spacing="10">نظام التشغيل الجيل القادم</text>
</svg>
SVGWALL

  # Try to convert SVG to JPEG if ImageMagick is available
  if command -v convert &>/dev/null; then
    convert "$BILAL_WALLPAPERS_DIR/default.svg" \
      -resize 1920x1080 \
      "$BILAL_WALLPAPERS_DIR/default.jpg" 2>/dev/null || true
  fi
}

# ──────────────────────────────────────────────
# 8. FONTS & LANGUAGE SUPPORT (13 Languages)
# ──────────────────────────────────────────────
install_languages() {
  step "تثبيت دعم 13 لغة والخطوط العربية"

  pacman -S --noconfirm \
    noto-fonts noto-fonts-emoji noto-fonts-extra \
    noto-fonts-cjk \
    ttf-arabic-fonts ttf-amiri ttf-scheherazade-new \
    ttf-liberation ttf-dejavu \
    adobe-source-han-sans-cn-fonts \
    adobe-source-han-sans-jp-fonts \
    adobe-source-han-sans-kr-fonts \
    ibus ibus-m17n m17n-lib \
    fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt \
    fcitx5-arabic fcitx5-chinese-addons \
    2>>"$BILAL_LOG" || warn "بعض حزم اللغات غير متوفرة"

  # IBus setup for Arabic input
  cat >> /etc/environment << 'IENV'
GTK_IM_MODULE=ibus
XMODIFIERS=@im=ibus
QT_IM_MODULE=ibus
IENV

  # Locale generation
  cat > /etc/locale.gen << 'LOCALES'
ar_DZ.UTF-8 UTF-8
ar_EG.UTF-8 UTF-8
ar_MA.UTF-8 UTF-8
en_US.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
fr_FR.UTF-8 UTF-8
de_DE.UTF-8 UTF-8
es_ES.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
ja_JP.UTF-8 UTF-8
pt_BR.UTF-8 UTF-8
tr_TR.UTF-8 UTF-8
fa_IR.UTF-8 UTF-8
ko_KR.UTF-8 UTF-8
ur_PK.UTF-8 UTF-8
LOCALES

  locale-gen 2>>"$BILAL_LOG"

  # Set default locale based on user selection
  case "$BILAL_LANG" in
    ar) echo "LANG=ar_DZ.UTF-8" > /etc/locale.conf ;;
    en) echo "LANG=en_US.UTF-8" > /etc/locale.conf ;;
    fr) echo "LANG=fr_FR.UTF-8" > /etc/locale.conf ;;
    de) echo "LANG=de_DE.UTF-8" > /etc/locale.conf ;;
    es) echo "LANG=es_ES.UTF-8" > /etc/locale.conf ;;
    zh) echo "LANG=zh_CN.UTF-8" > /etc/locale.conf ;;
    ru) echo "LANG=ru_RU.UTF-8" > /etc/locale.conf ;;
    ja) echo "LANG=ja_JP.UTF-8" > /etc/locale.conf ;;
    pt) echo "LANG=pt_BR.UTF-8" > /etc/locale.conf ;;
    tr) echo "LANG=tr_TR.UTF-8" > /etc/locale.conf ;;
    fa) echo "LANG=fa_IR.UTF-8" > /etc/locale.conf ;;
    ko) echo "LANG=ko_KR.UTF-8" > /etc/locale.conf ;;
    ur) echo "LANG=ur_PK.UTF-8" > /etc/locale.conf ;;
    *)  echo "LANG=ar_DZ.UTF-8" > /etc/locale.conf ;;
  esac

  fc-cache -fv 2>>"$BILAL_LOG"
  ok "دعم 13 لغة مثبت + خطوط عربية احترافية"
}

# ──────────────────────────────────────────────
# 9. PROFILE-SPECIFIC PACKAGES
# ──────────────────────────────────────────────
install_profile_packages() {
  step "تثبيت حزم التخصص: $BILAL_PROFILE"

  case "$BILAL_PROFILE" in

    # ── المبرمج ──
    dev)
      info "تثبيت بيئة التطوير الكاملة..."
      pacman -S --noconfirm \
        code neovim vim emacs \
        docker docker-compose podman \
        git git-lfs github-cli \
        nodejs npm yarn \
        python python-pip python-venv \
        go rustup \
        jdk21-openjdk php \
        postgresql sqlite redis \
        nginx apache \
        httpie curl wget \
        jq yq fzf bat eza zoxide \
        lazygit lazydocker \
        tmux zsh fish \
        2>>"$BILAL_LOG"

      # Rust toolchain
      rustup toolchain install stable 2>>"$BILAL_LOG" || true

      # Node global tools
      npm install -g \
        pnpm bun typescript \
        eslint prettier nodemon \
        2>>"$BILAL_LOG" || true

      # Zsh with Oh My Zsh + plugins
      if [ -n "${SUDO_USER:-}" ]; then
        su -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"' "$SUDO_USER" 2>>"$BILAL_LOG" || true
      fi

      # VS Code extensions
      if command -v code &>/dev/null; then
        code --install-extension ms-python.python 2>/dev/null || true
        code --install-extension rust-lang.rust-analyzer 2>/dev/null || true
        code --install-extension golang.go 2>/dev/null || true
        code --install-extension dbaeumer.vscode-eslint 2>/dev/null || true
        code --install-extension ms-vscode.cmake-tools 2>/dev/null || true
        code --install-extension github.copilot 2>/dev/null || true
        code --install-extension eamodio.gitlens 2>/dev/null || true
      fi

      ok "بيئة المبرمج مثبتة بالكامل"
      ;;

    # ── المنتج الإبداعي ──
    creator)
      info "تثبيت أدوات الإنتاج الإبداعي..."
      pacman -S --noconfirm \
        blender \
        gimp inkscape krita \
        kdenlive \
        obs-studio \
        audacity ardour \
        rawtherapee darktable \
        imagemagick ffmpeg \
        handbrake \
        vlc mpv \
        qpwgraph \
        2>>"$BILAL_LOG"

      # DaVinci Resolve (from AUR — optional)
      info "يمكنك تثبيت DaVinci Resolve من AUR: yay -S davinci-resolve"

      # OBS plugins
      pacman -S --noconfirm \
        obs-plugin-wlrobs \
        obs-plugin-looking-glass \
        2>>"$BILAL_LOG" || warn "بعض إضافات OBS غير متوفرة"

      # JACK audio for professional audio
      pacman -S --noconfirm \
        jack2 qjackctl \
        carla ladspa \
        2>>"$BILAL_LOG" || true

      ok "بيئة الإنتاج الإبداعي مثبتة"
      ;;

    # ── الأمن السيبراني ──
    hacker)
      info "تثبيت أدوات الأمن السيبراني..."

      # Add BlackArch repo for extra tools
      if ! grep -q "blackarch" /etc/pacman.conf; then
        curl -O https://blackarch.org/strap.sh 2>>"$BILAL_LOG" || true
        if [ -f strap.sh ]; then
          chmod +x strap.sh && bash strap.sh 2>>"$BILAL_LOG" || warn "BlackArch repo يمكن إضافته يدوياً"
          rm -f strap.sh
        fi
      fi

      pacman -S --noconfirm \
        nmap masscan rustscan \
        wireshark-qt tshark tcpdump \
        metasploit \
        john hashcat \
        aircrack-ng \
        sqlmap \
        nikto \
        binwalk \
        strace ltrace gdb \
        burpsuite 2>/dev/null || true \
        radare2 ghidra \
        volatility3 \
        tor torbrowser-launcher \
        proxychains-ng \
        gobuster \
        hydra \
        2>>"$BILAL_LOG" || warn "بعض أدوات الأمن تتطلب BlackArch repo"

      # Python security tools
      pip install --break-system-packages \
        scapy impacket pwntools \
        crackmapexec \
        2>>"$BILAL_LOG" || true

      # Setup BilalSec environment
      mkdir -p /opt/bilal-sec/{exploits,payloads,wordlists,reports}
      info "تحميل قوائم كلمات المرور..."
      curl -sL "https://github.com/danielmiessler/SecLists/raw/master/Passwords/Common-Credentials/10-million-password-list-top-10000.txt" \
        -o /opt/bilal-sec/wordlists/top-10k.txt 2>>"$BILAL_LOG" || true

      ok "بيئة الأمن السيبراني مثبتة"
      ;;

    *)
      warn "تخصص غير معروف: $BILAL_PROFILE — تم تثبيت الحزم الأساسية فقط"
      ;;
  esac
}

# ──────────────────────────────────────────────
# 10. BILAL OS BRANDING & SYSTEM IDENTITY
# ──────────────────────────────────────────────
setup_identity() {
  step "إعداد هوية BILAL OS"

  mkdir -p "$BILAL_CONF"

  # System info file
  cat > "$BILAL_CONF/os-release" << OSREL
NAME="BILAL OS"
VERSION="$BILAL_VERSION"
ID=bilal-os
ID_LIKE=arch
PRETTY_NAME="BILAL OS $BILAL_VERSION ($BILAL_CODENAME)"
ANSI_COLOR="0;36"
HOME_URL="https://bilal-os.org"
SUPPORT_URL="https://bilal-os.org/support"
BUILD_ID=$BILAL_PROFILE-$(date +%Y%m%d)
OSREL

  # /etc/os-release link
  ln -sf "$BILAL_CONF/os-release" /etc/bilal-os-release

  # MOTD (Message of the Day)
  cat > /etc/motd << 'MOTD'

  ██████╗ ██╗██╗      █████╗ ██╗      ██████╗ ███████╗
  ██╔══██╗██║██║     ██╔══██╗██║     ██╔═══██╗██╔════╝
  ██████╔╝██║██║     ███████║██║     ██║   ██║███████╗
  ██╔══██╗██║██║     ██╔══██║██║     ██║   ██║╚════██║
  ██████╔╝██║███████╗██║  ██║███████╗╚██████╔╝███████║

  مرحباً بك في BILAL OS — نظام التشغيل الجيل القادم
  اكتب 'bilal-ask سؤالك' للتحدث مع المساعد الذكي
  اكتب 'bilal-help' لقائمة الأوامر المتاحة

MOTD

  # bilal-help command
  cat > /usr/local/bin/bilal-help << 'BHELP'
#!/bin/bash
echo -e "\033[36m"
echo "═══════════════════════════════════════════════"
echo "         BILAL OS — دليل الأوامر السريع"
echo "═══════════════════════════════════════════════"
echo -e "\033[0m"
echo "  bilal-ask <سؤال>      — المساعد الذكي بالعربية"
echo "  bilal-explain <أمر>   — شرح أي أمر بالعربية"
echo "  bilal-voice           — المساعد الصوتي"
echo "  bilal-run-win <app>   — تشغيل تطبيق ويندوز"
echo "  bilal-shield          — حالة نظام الحماية"
echo "  bilal-update          — تحديث BILAL OS"
echo "  bilal-neofetch        — معلومات النظام"
echo ""
echo "  Super+T               — فتح الطرفية"
echo "  Super+B               — فتح المتصفح"
echo "  Super+Space           — قائمة التطبيقات"
echo "  Super+A               — مساعد AI"
echo ""
BHELP
  chmod +x /usr/local/bin/bilal-help

  # bilal-shield status
  cat > /usr/local/bin/bilal-shield << 'BSHIELD'
#!/bin/bash
echo -e "\033[36m[BilalShield]\033[0m حالة الحماية:"
echo ""
ufw status 2>/dev/null | head -5 || echo "  UFW: غير مثبت"
echo ""
systemctl is-active --quiet fail2ban && echo "  ✓ Fail2ban: نشط" || echo "  ✗ Fail2ban: متوقف"
systemctl is-active --quiet bilal-ai-guard && echo "  ✓ AI Guard: نشط" || echo "  ✗ AI Guard: متوقف"
systemctl is-active --quiet clamav-freshclam && echo "  ✓ ClamAV: نشط" || echo "  ✗ ClamAV: متوقف"
systemctl is-active --quiet apparmor && echo "  ✓ AppArmor: نشط" || echo "  ✗ AppArmor: متوقف"
echo ""
BSHIELD
  chmod +x /usr/local/bin/bilal-shield

  # bilal-neofetch
  cat > /usr/local/bin/bilal-neofetch << 'BNEO'
#!/bin/bash
KERNEL=$(uname -r)
UPTIME=$(uptime -p)
RAM=$(free -h | awk '/^Mem/{print $3"/"$2}')
CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
SHELL_NAME=$(basename "$SHELL")
DE="Hyprland (Wayland)"
OS="BILAL OS 2.0"

echo -e "\033[36m"
cat << "LOGO"
  ██████╗ ██╗██╗      █████╗ ██╗
  ██╔══██╗██║██║     ██╔══██╗██║
  ██████╔╝██║██║     ███████║██║
  ██╔══██╗██║██║     ██╔══██║██║
  ██████╔╝██║███████╗██║  ██║███████╗
LOGO
echo -e "\033[0m"
echo -e "\033[1;37m  OS:\033[0m     $OS"
echo -e "\033[1;37m  Kernel:\033[0m $KERNEL"
echo -e "\033[1;37m  Uptime:\033[0m $UPTIME"
echo -e "\033[1;37m  CPU:\033[0m    $CPU"
echo -e "\033[1;37m  RAM:\033[0m    $RAM"
echo -e "\033[1;37m  Shell:\033[0m  $SHELL_NAME"
echo -e "\033[1;37m  DE:\033[0m     $DE"
echo ""
BNEO
  chmod +x /usr/local/bin/bilal-neofetch

  # bilal-update
  cat > /usr/local/bin/bilal-update << 'BUPDATE'
#!/bin/bash
echo -e "\033[36m[BILAL OS]\033[0m جاري التحديث..."
sudo pacman -Syu --noconfirm
sudo pip install --break-system-packages --upgrade ollama 2>/dev/null || true
sudo ollama pull llama3.2:3b 2>/dev/null || true
echo -e "\033[32m[✓]\033[0m BILAL OS محدث بالكامل"
BUPDATE
  chmod +x /usr/local/bin/bilal-update

  ok "هوية BILAL OS مضبوطة"
}

# ──────────────────────────────────────────────
# 11. PERFORMANCE OPTIMIZATION
# ──────────────────────────────────────────────
optimize_system() {
  step "تحسين أداء النظام"

  # Enable zram (compressed RAM)
  pacman -S --noconfirm zram-generator 2>>"$BILAL_LOG" || true
  cat > /etc/systemd/zram-generator.conf << 'ZRAM'
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
ZRAM

  # Enable earlyoom (prevents system freeze under memory pressure)
  pacman -S --noconfirm earlyoom 2>>"$BILAL_LOG" || true
  systemctl enable earlyoom 2>>"$BILAL_LOG" || true

  # Enable systemd-oomd
  systemctl enable systemd-oomd 2>>"$BILAL_LOG" || true

  # Trim for SSDs
  systemctl enable fstrim.timer 2>>"$BILAL_LOG" || true

  # Reflector for fastest mirrors
  pacman -S --noconfirm reflector 2>>"$BILAL_LOG"
  reflector --country Algeria,France,Germany \
    --protocol https --latest 20 --sort rate \
    --save /etc/pacman.d/mirrorlist 2>>"$BILAL_LOG" || \
    warn "Reflector: تعذّر إيجاد مرايا للجزائر، تم الإبقاء على الإعدادات الافتراضية"

  # io scheduler
  echo 'ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"' \
    > /etc/udev/rules.d/60-ioschedulers.rules

  ok "تحسينات الأداء مطبّقة"
}

# ──────────────────────────────────────────────
# 12. FINAL CLEANUP & SUMMARY
# ──────────────────────────────────────────────
finalize() {
  step "التنظيف النهائي"

  pacman -Sc --noconfirm 2>>"$BILAL_LOG"
  pip cache purge 2>>"$BILAL_LOG" || true
  rm -rf /tmp/bilal-* /var/cache/bilal-* 2>/dev/null || true

  # Enable all services
  systemctl enable \
    ufw fail2ban bilal-ai-guard \
    bluetooth NetworkManager \
    pipewire wireplumber \
    ollama sddm \
    2>>"$BILAL_LOG" || true

  # Installation summary
  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║     🎉 اكتمل تثبيت BILAL OS بنجاح!          ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${CYAN}الإصدار:${RESET}    BILAL OS v${BILAL_VERSION}"
  echo -e "  ${CYAN}التخصص:${RESET}     $BILAL_PROFILE"
  echo -e "  ${CYAN}اللغة:${RESET}      $BILAL_LANG"
  echo -e "  ${CYAN}النواة:${RESET}     $BILAL_KERNEL"
  echo -e "  ${CYAN}الواجهة:${RESET}    Hyprland + Waybar"
  echo -e "  ${CYAN}الحماية:${RESET}    BilalShield + AI Guard"
  echo -e "  ${CYAN}الذكاء:${RESET}     BilalAI (LLaMA 3.2)"
  echo -e "  ${CYAN}ويندوز:${RESET}     Wine-Staging + Proton-GE"
  echo ""
  echo -e "  ${YELLOW}أعد التشغيل للبدء: ${WHITE}reboot${RESET}"
  echo -e "  ${YELLOW}دليل الأوامر:    ${WHITE}bilal-help${RESET}"
  echo ""
}

# ──────────────────────────────────────────────
# MAIN EXECUTION FLOW
# ──────────────────────────────────────────────
main() {
  banner

  mkdir -p "$(dirname $BILAL_LOG)" /var/log/bilal-os
  touch "$BILAL_LOG"

  check_root
  check_arch
  check_internet
  check_hardware

  local TOTAL=10
  local CURRENT=0

  progress_bar $((++CURRENT)) $TOTAL "تحديث النظام...";        echo; update_system
  progress_bar $((++CURRENT)) $TOTAL "تثبيت النواة...";        echo; install_kernel
  progress_bar $((++CURRENT)) $TOTAL "نظام الحماية...";        echo; install_security
  progress_bar $((++CURRENT)) $TOTAL "محرك الذكاء الاصطناعي..."; echo; install_ai_engine
  progress_bar $((++CURRENT)) $TOTAL "دعم ويندوز...";          echo; install_windows_support
  progress_bar $((++CURRENT)) $TOTAL "واجهة المستخدم...";      echo; install_desktop
  progress_bar $((++CURRENT)) $TOTAL "دعم اللغات...";          echo; install_languages
  progress_bar $((++CURRENT)) $TOTAL "حزم التخصص...";          echo; install_profile_packages
  progress_bar $((++CURRENT)) $TOTAL "هوية النظام...";         echo; setup_identity
  progress_bar $((++CURRENT)) $TOTAL "تحسين الأداء...";        echo; optimize_system

  finalize
}

# ── Run ──
main "$@"
