# Creating an AppImage from a spack environment

HPC container runtimes often use squashfs as an archive to store an image, which is then mounted on compute nodes and made writeable using overlayfs where the top layer is a ramfs. This trick gives good performance particularly on shared filesystems, since the squashfs file is a single blob on the disk and has good caching behavior.

However, perfect isolation from the host system is not always possible, in particular when vendor optimized libraries (e.g. cuda and mpi) have to be mounted into the container, and the question is what the point of containers really is if they still depend on the host system.

Instead of using containers, one can still deploy applications as a single self-contained blob on the filesystem by using the AppImage runtime. The basic idea is to create an executable which unwraps and mounts a squashfs file baked into the binary.

This repo shows how to do that using spack environments, where we install [SIRIUS](https://github.com/electronic-structure/SIRIUS/), bundle it using [libtree](https://github.com/haampie/libtree) and then create a self-unwrapping binary using the [AppImage runtime](https://github.com/AppImage/AppImageKit).

## Building

```console
$ ./build.sh
```

## Running

```console
$ ./sirius.app sirius.scf
SIRIUS 6.5.7, git hash: https://api.github.com/repos/electronic-structure/SIRIUS/git/ref/tags/v6.5.7

SIRIUS version : 6.5.7
git hash       : https://api.github.com/repos/electronic-structure/SIRIUS/git/ref/tags/v6.5.7
git branch     : release v6.5.7
build time     : 2021-03-23 10:46:06
start time     : Tue, 23 Mar 2021 12:34:25

number of MPI ranks           : 1
MPI grid                      : 1 1 1
maximum number of OMP threads : 16

...


$ ./sirius.app atom
$ ./sirius.app atom
SIRIUS 6.5.7, git hash: https://api.github.com/repos/electronic-structure/SIRIUS/git/ref/tags/v6.5.7

Atom (L)APW+lo basis generation.

Usage: atom [options]
Options:
  --help     print this help and exit
  --symbol=  {string} symbol of a chemical element
  --type=    {lo1, lo2, lo3, LO1, LO2} type of local orbital basis
  --core=    {double} cutoff for core states: energy (in Ha, if <0), radius (in a.u. if >0)
  --order=   {int} order of augmentation
  --apw_enu= {double} default value for APW linearization energies
  --auto_enu allow search of APW linearization energies
  --xml      xml output for Exciting code
  --rel      use scalar-relativistic solver
```
