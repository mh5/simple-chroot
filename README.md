# simple-chroot

simple-chroot is a bash script that manages installation and uninstallation of executable files on chrooted environments. The script automatically identifies the dependencies of the executables you want to install and clones them if necessary. It also allows uninstalling software and deletes its dependencies if they are not needed anymore.

##Installing packages

```
# installing bash, vim and another executable.
$ ./simple-chroot.sh install bash vim /link/to/another/executable
```

## Uninstalling files
```
# uninstalling vim and another executable.
$ ./simple-chroot.sh purge vim /link/to/another/executable
```
