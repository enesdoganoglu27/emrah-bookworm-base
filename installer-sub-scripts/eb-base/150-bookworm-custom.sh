# ------------------------------------------------------------------------------
# BOOKWORM_CUSTOM.SH
# ------------------------------------------------------------------------------
set -e
source $INSTALLER/000-source

# ------------------------------------------------------------------------------
# ENVIRONMENT
# ------------------------------------------------------------------------------
MACH="$TAG-bookworm"
cd $MACHINES/$MACH

ROOTFS="/var/lib/lxc/$MACH/rootfs"

# ------------------------------------------------------------------------------
# INIT
# ------------------------------------------------------------------------------
[[ "$BOOKWORM_SKIPPED" = true ]] && exit
[[ "$DONT_RUN_BOOKWORM_CUSTOM" = true ]] && exit

echo
echo "---------------------- $MACH CUSTOM -----------------------"

# start container
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING

# wait for the network to be up
for i in $(seq 0 9); do
    lxc-attach -n $MACH -- ping -c1 host.loc && break || true
    sleep 1
done

# ------------------------------------------------------------------------------
# PACKAGES
# ------------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- zsh <<EOS
set -e
export DEBIAN_FRONTEND=noninteractive

for i in 1 2 3; do
    sleep 1
    apt-get -y --allow-releaseinfo-change update && sleep 3 && break
done

apt-get $APT_PROXY -y dist-upgrade
EOS

# packages
lxc-attach -n $MACH -- zsh <<EOS
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get $APT_PROXY -y install less tmux vim autojump
apt-get $APT_PROXY -y install curl dnsutils
apt-get $APT_PROXY -y install net-tools ngrep ncat
apt-get $APT_PROXY -y install htop bmon bwm-ng
apt-get $APT_PROXY -y install rsync bzip2 man-db ack
EOS

# ------------------------------------------------------------------------------
# ROOT USER
# ------------------------------------------------------------------------------
# shell
cp /tmp/eb/machines/common/home/user/.bashrc $ROOTFS/root/
cp /tmp/eb/machines/common/home/user/.vimrc $ROOTFS/root/
cp /tmp/eb/machines/common/home/user/.zshrc $ROOTFS/root/
cp /tmp/eb/machines/common/home/user/.tmux.conf $ROOTFS/root/
lxc-attach -n $MACH -- chsh -s /bin/zsh root
#cp ../../common/home/user/.bashrc $ROOTFS/root/
#cp ../../common/home/user/.vimrc $ROOTFS/root/
#cp ../../common/home/user/.zshrc $ROOTFS/root/
#cp ../../common/home/user/.tmux.conf $ROOTFS/root/

# ------------------------------------------------------------------------------
# CONTAINER SERVICES
# ------------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
