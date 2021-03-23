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

## Running on piz daint

For Piz Daint I've modified the `sirius/spack.yaml` a bit so that it links against system libmpi.so (`^cray-mpich` that is):

```
daint103 $ ./build.sh
...

daint103 $ du -sh sirius.app # binary size (includes compressed squashfs)
26M	sirius.app

daint103 $ ./sirius.app --appimage-extract # runtime allows you to extract
squashfs-root/AppRun
squashfs-root/usr
squashfs-root/usr/bin
squashfs-root/usr/bin/atom
squashfs-root/usr/bin/sirius.scf
squashfs-root/usr/lib
squashfs-root/usr/lib/libAtpSigHandler.so.1
squashfs-root/usr/lib/libAtpSigHandler.so.1.0.1
squashfs-root/usr/lib/libcuda.so.1
squashfs-root/usr/lib/libcuda.so.450.51.05
...

daint103 $ du -sh squashfs-root # uncompressed size
70M	squashfs-root/

daint103 $ srun ... -Cmc -N1 -n2 -c2 --time=00:01:00 ./sirius.app sirius.scf # run sirius.scf with cray mpi
srun: job 30079568 queued and waiting for resources
srun: job 30079568 has been allocated resources
SIRIUS 6.5.7, git hash: https://api.github.com/repos/electronic-structure/SIRIUS/git/ref/tags/v6.5.7
input file does not exist
===========================================================================================================
                            #         Total          %   Parent %        Median           Min           Max
-----------------------------------------------------------------------------------------------------------
sirius                      1       2.30 ms     100.00     100.00       2.30 ms       2.30 ms       2.30 ms
 |- sirius::initialize      1       1.40 ms      60.83      60.83       1.40 ms       1.40 ms       1.40 ms
 |- sirius::finalize        1     333.28 us      14.52      14.52     333.28 us     333.28 us     333.28 us

===========================================================================================================
```

