#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status

# This script automates the download of SaxonC-HE and the installation
# of its PHP module specifically within a php-fpm Docker container build.

# --- Configuration & Temporary Paths ---
SAXON_TMP_DIR="/tmp/saxon_installer"
SAXONC_HOME="" # This will be set dynamically after download

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting SaxonC installation on Debian-based Docker image..."

# --- 1. Install Build Dependencies ---
echo "Installing build dependencies..."

# List of packages this script intends to install for build and utility purposes.
# openjdk-17-jre-headless is NOT in this list as it's a runtime dependency and should NOT be purged.
BUILD_AND_UTILITY_PACKAGES="build-essential libxml2-dev libxslt1-dev curl unzip"

# Take a snapshot of all currently installed packages *before* this script installs anything new.
# This list will be used later to determine which packages were installed *by this script*.
echo "Taking snapshot of currently installed Debian packages for selective purging later..."
INSTALLED_PACKAGES_BEFORE_SCRIPT=$(apt list --installed 2>/dev/null | awk -F'/' '{print $1}' | tail -n +2)

# Perform the actual package installation
# `apt-get install` is idempotent; it will only download and install
# packages that are not already present or not at the latest version.
apt-get update -y
apt-get install -y --no-install-recommends $BUILD_AND_UTILITY_PACKAGES

# Clean up apt lists immediately after installing to reduce image size
rm -rf /var/lib/apt/lists/*
echo "Prerequisites installed successfully."

# --- 2. SaxonC Version Detection & Download ---
# --- Step 2: Download and Extract SaxonC-HE ---
echo "--- Step 2: Downloading and extracting SaxonC-HE ---"
mkdir -p "$SAXON_TMP_DIR"
cd "$SAXON_TMP_DIR"

echo "Detecting system architecture and latest SaxonC version..."
UNAME_ARCH=$(uname -m)
DOWNLOAD_ARCH_COMPONENT=""

case "$UNAME_ARCH" in
    x86_64) DOWNLOAD_ARCH_COMPONENT="linux-x86_64";;
    aarch64|arm64) DOWNLOAD_ARCH_COMPONENT="linux-aarch64";;
    *)
        echo "Error: Unsupported architecture: '$UNAME_ARCH'. Script needs Linux x86_64 or aarch64/arm64. Exiting." >&2
        exit 1
        ;;
esac

echo "Detected architecture: ${UNAME_ARCH}"

# Fetch the latest SaxonC version information from Saxonica's XML feed.
# This entire block is a single, robust command to handle variable scope in RUN.
ALL_OUTPUT=$(curl -s https://www.saxonica.com/products/latest.xml | \
grep -A 1 -E '<h2>SaxonC 13</h2>|<h2>SaxonC 12</h2>' | \
awk '/<h2>SaxonC 13<\/h2>/ {f13=1;next} /<h2>SaxonC 12<\/h2>/ {if(!f13){f12=1;next}} {if(f13||f12){match($0, /[0-9]+(\.[0-9]+)*/);if(RSTART>0){v=substr($0, RSTART, RLENGTH); \
if(f13){print "SaxonC 13: " v}else{print "SaxonC 12: " v}; \
split(v,p,"."); \
mv=p[1];dv=p[1]; \
for(i=2;i<=length(p);i++){dv=dv"-"p[i]}; \
if(length(p)==2){dv=dv"-0"}else if(length(p)==1){dv=dv"-0-0"}; \
print mv,dv; exit}}}')

if [ -z "$ALL_OUTPUT" ]; then
    echo "Error: Could not determine latest SaxonC version from saxonica.com. Exiting." >&2
    exit 1
fi

DETECTED_VERSION_DISPLAY_LINE=$(echo "$ALL_OUTPUT" | head -n 1)
MACHINE_READABLE_INFO=$(echo "$ALL_OUTPUT" | tail -n 1)
MAJOR_VER=$(echo "$MACHINE_READABLE_INFO" | awk '{print $1}')
FORMATTED_VER=$(echo "$MACHINE_READABLE_INFO" | awk '{print $2}')

echo "$DETECTED_VERSION_DISPLAY_LINE"
CONSTRUCTED_URL="https://downloads.saxonica.com/SaxonC/HE/${MAJOR_VER}/SaxonCHE-${DOWNLOAD_ARCH_COMPONENT}-${FORMATTED_VER}.zip"
echo "Downloading from: $CONSTRUCTED_URL"
curl -L -o saxon.zip "$CONSTRUCTED_URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download SaxonCHE from '$CONSTRUCTED_URL'. Please check your internet connection or the URL. Exiting." >&2
    exit 1
fi

echo "Unzipping SaxonCHE..."
unzip saxon.zip

# Find the extracted directory name more flexibly.
SAXONC_UNZIPPED_NAME=$(find . -maxdepth 1 -type d -name "SaxonCHE-*" | head -n 1)

if [ -z "$SAXONC_UNZIPPED_NAME" ]; then
    echo "Error: Could not find extracted SaxonC-HE directory (expected 'SaxonCHE-*')." >&2
    exit 1
fi

# Set SAXONC_HOME to the *root* of the extracted SaxonC distribution.
SAXONC_HOME="${SAXON_TMP_DIR}/${SAXONC_UNZIPPED_NAME}"

# Define the paths relative to SAXONC_HOME based on the SaxonC package structure.
SAXONC_PHP_SRC="${SAXONC_HOME}/php/src"
SAXONC_LIB_PATH="${SAXONC_HOME}/SaxonCHE/lib"
SAXONC_INCLUDE_PATH="${SAXONC_HOME}/SaxonCHE/include"

echo "SaxonC-HE extracted to: ${SAXONC_HOME}"
rm saxon.zip

# Final checks to ensure required directories exist within the extracted package.
if [ ! -d "$SAXONC_PHP_SRC" ]; then
    echo "Error: PHP source directory not found at '$SAXONC_PHP_SRC'. Downloaded package structure might have changed. Exiting."
    exit 1
fi

if [ ! -d "$SAXONC_LIB_PATH" ]; then
    echo "Error: SaxonC library directory not found at '$SAXONC_LIB_PATH'. Downloaded package structure might have changed. Exiting."
    exit 1
fi

echo "SaxonC-HE download and extraction complete."

# --- Step 3: Compile the PHP Extension ---
echo "--- Step 3: Compiling the SaxonC PHP extension ---"
echo "Navigating to PHP extension source: ${SAXONC_PHP_SRC}"
cd "${SAXONC_PHP_SRC}"

echo "Running phpize..."
phpize

# Export LDFLAGS and CXXFLAGS/CFLAGS to ensure the linker and compiler find the necessary paths.
# These exports are specific to this RUN command context.
echo "Exporting LDFLAGS='-L${SAXONC_LIB_PATH}'"
export LDFLAGS="-L${SAXONC_LIB_PATH}"
echo "Exporting CXXFLAGS='-I${SAXONC_INCLUDE_PATH}' and CFLAGS='-I${SAXONC_INCLUDE_PATH}'"
export CXXFLAGS="-I${SAXONC_INCLUDE_PATH}"
export CFLAGS="-I${SAXONC_INCLUDE_PATH}"

echo "Configuring the extension with SaxonC base path: ${SAXONC_HOME}/SaxonCHE"
./configure --with-saxon="${SAXONC_HOME}/SaxonCHE" || { echo "Configure failed. Check config.log for details."; cat config.log; exit 1; }

echo "Compiling the extension..."
make -j$(nproc) || { echo "Make failed. Check for compilation errors."; exit 1; }

# Unset environment variables after successful compilation to avoid affecting subsequent commands in this shell.
echo "Unsetting LDFLAGS, CXXFLAGS, CFLAGS."
unset LDFLAGS CXXFLAGS CFLAGS

echo "Installing the compiled extension..."
# `make install` places `saxon.so` into PHP's default extension directory (e.g., /usr/local/lib/php/extensions/no-debug-non-zts-*)
make install

echo "SaxonC PHP extension compilation and installation complete."

# --- Step 4: Create and Enable Module Configuration File ---
echo "--- Step 4: Creating and enabling the PHP module configuration file ---"
# Official PHP Docker images look for .ini files in /usr/local/etc/php/conf.d/
PHP_INI_CONF_D="/usr/local/etc/php/conf.d"
INI_FILE="${PHP_INI_CONF_D}/20-saxon.ini"

echo "Creating INI file at: ${INI_FILE}"
mkdir -p "${PHP_INI_CONF_D}" # Ensure the conf.d directory exists.
echo "; configuration for php Saxon HE/PE/EE module" > "${INI_FILE}"
echo "extension=saxon.so" >> "${INI_FILE}"

echo "PHP module configuration complete."

# --- Step 5: Copy SaxonC Libraries to a persistent location ---
# This is vital. The native SaxonC libraries need to be copied from the
# temporary build location to a permanent directory in the Docker image
# so they are available at runtime.
echo "--- Step 5: Copying SaxonC native libraries ---"
FINAL_SAXON_LIB_DIR="/usr/local/saxon/lib"
mkdir -p "${FINAL_SAXON_LIB_DIR}"
cp -R "${SAXONC_LIB_PATH}"/* "${FINAL_SAXON_LIB_DIR}/"

echo "SaxonC native libraries copied to: ${FINAL_SAXON_LIB_DIR}"

# --- Step 6: Configure Dynamic Linker Cache (NEW STEP) ---
echo "--- Step 6: Configuring Dynamic Linker Cache for SaxonC libraries ---"
# Create a .conf file in /etc/ld.so.conf.d/ pointing to the SaxonC library path.
# This tells the system's dynamic linker where to find libsaxonc-he.so.12 and other related libraries.
echo "${FINAL_SAXON_LIB_DIR}" > /etc/ld.so.conf.d/saxon.conf

# Update the dynamic linker's cache. This is crucial for the change to take effect immediately
# within the Docker image layer, ensuring PHP-FPM can find the libraries at runtime.
ldconfig

echo "Dynamic linker cache updated. SaxonC libraries should now be discoverable at runtime."

# --- Step 7: Clean up temporary files ---
echo "--- Step 7: Cleaning up temporary files ---"
# Remove the temporary SaxonC installer directory to reduce final image size.
rm -rf "$SAXON_TMP_DIR"

# Iterate through the list of packages that this script installed for build/utility purposes.
# Only purge those packages that were *not* present before this script ran.
for PKG in $BUILD_AND_UTILITY_PACKAGES; do
    # Check if the package was NOT in the snapshot taken before this script's installations.
    # If it wasn't, it means this script installed it, and it's safe to purge.
    # `grep -q -F -x "$PKG"` searches for an exact fixed string match for $PKG.
    if ! echo "$INSTALLED_PACKAGES_BEFORE_SCRIPT" | grep -q -F -x "$PKG"; then
        echo "Purging package: $PKG (installed by this script)"
        apt-get purge -y --auto-remove "$PKG" || true # `|| true` prevents script from failing if purge fails
    else
        echo "Keeping package: $PKG (already present before this script ran)"
    fi
done

# Ensure apt lists are cleaned even if no purge happens, or only some packages are purged.
apt-get clean && rm -rf /var/lib/apt/lists/*
echo "Cleanup complete."


# --- Verification at the end of the script ---
echo "Verifying final Saxon/C installation status:"

# Re-run checks to get current status
php -m | grep saxon -i