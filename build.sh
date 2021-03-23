#/bin/bash

set -e

# download appimage runtime
echo "Installing tools..."
wget -qO runtime https://github.com/AppImage/AppImageKit/releases/download/12/runtime-x86_64
spack -e ./libtree install

# install the environment in this folder
echo "Installing the environment..."
spack -e ./sirius install

# bundle sirius.scf and atom binaries into sirius.app
echo "Bundling the binaries..."
./libtree/.spack-env/view/bin/libtree \
    --strip \
    --chrpath \
    -d sirius.bundle \
    ./sirius/.spack-env/view/bin/sirius.scf \
    ./sirius/.spack-env/view/bin/atom

echo "Setting up entry point..."
cp AppRun sirius.bundle/AppRun

# create a squashfs out of this
echo "Making a squashfs..."
mksquashfs sirius.bundle/ sirius.squashfs -root-owned -noappend

# Set up the appimage executable
echo "Building sirius.app..."
cat runtime > sirius.app
cat sirius.squashfs >> sirius.app
chmod a+x sirius.app

echo "Cleaning stuff..."
rm -rf sirius.bundle sirius.squashfs

echo "Done! Now run './sirius.app sirius.scf' or './sirius.app atom'"

