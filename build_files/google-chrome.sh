#!/usr/bin/env sh

set -ouex pipefail

echo "Installing Google Chrome"

# On libostree systems, /opt is a symlink to /var/opt,
# which actually only exists on the live system. /var is
# a separate mutable, stateful FS that's overlaid onto
# the ostree rootfs. Therefore we need to install it into
# /usr/lib/1Password instead, and dynamically create a
# symbolic link /opt/1Password => /usr/lib/1Password upon
# boot.

# Prepare staging directory
mkdir -p /var/opt # -p just in case it exists
# for some reason...

# Setup repo
cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=Google Chrome Stable
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Import signing key
rpm --import https://dl.google.com/linux/linux_signing_key.pub

# Prepare 1Password groups
# Normally, when after dnf installs the 1password RPM, an
# 'after-install.sh' script runs to cofigure several things, including
# the creation of a group. Under rpm-ostree, this didn't work quite as
# expected, thus several steps were done to hack around and fix things.
# Now with dnf5, there is a problem where 'after-install.sh' creates
# groups which conflict with default user's GID. This now pre-creates
# the groups, rather than fixing after RPM installation.

# I hardcode GIDs and cross fingers that nothing else steps on them.
# These numbers _should_ be okay under normal use, but
# if there's a more specific range that I should use here
# please submit a PR!

# Specifically, GID must be > 1000, and absolutely must not
# conflict with any real groups on the deployed system.
# Normal user group GIDs on Fedora are sequential starting
# at 1000, so let's skip ahead and set to something higher.
GID_CHROME="1800"
groupadd -g ${GID_CHROME} google-chrome

# Now let's install the packages.
dnf5 install -y google-chrome

# This places the Google Chrome contents in an image safe location
mv /var/opt/google-chrome /usr/lib/google-chrome # move this over here

# Register path symlink
# We do this via tmpfiles.d so that it is created by the live system.
cat >/usr/lib/tmpfiles.d/google-chrome.conf <<EOF
L  /opt/google-chrome  -  -  -  -  /usr/lib/google-chrome
EOF

# No further hack SHOULD be needed since dnf5 does run the script
# after-install.sh as expected and uses our pre-set groups.

# Clean up the yum repo (updates are baked into new images)
rm /etc/yum.repos.d/google-chrome.repo -f