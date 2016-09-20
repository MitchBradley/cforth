#!/bin/bash
# dev.laptop.org #6210 test script
#
# Creates an ext2 filesystem on a USB stick for testing with OFW
#
# Instructions for use:
# - copy this file and ext2test.fth to a Linux machine
# - turn off X with 'telinit 4',
# - ensure that no USB stick is mounted
# - insert USB stick, wait seven seconds settling time,
# - execute this script "ext2test.sh /dev/sda",
# - remove USB stick,
# - insert in test laptop,
# - power up,
# - examine output.
#
set -e

function help {
    cat <<EOF
Usage: test.sh [options] device
    --help             display this help
    --end N            partition end specification for parted, -1s is the
                       default and means full size, or use a number followed
                       by s for a given number of sectors, see the parted(8)
                       unit command.
    device             the device you wish to write to, e.g. /dev/sdZ
EOF
}

DEVICE=
END=-1s
while [ ! -z "${1}" ]; do
    case "${1}" in
	--end)
	    shift
	    END=${1}
	    shift
	    echo "test.sh: partition end to be set to ${END}"
	    ;;
	--help)
	    shift
	    help
	    exit 0
	    ;;
	*)
	    DEVICE=${1}
	    shift
#	    if [ ! -e ${DEVICE} ]; then
#		echo "test.sh: no such device ${DEVICE}"
#		exit 1
#	    fi
    esac

done

if [ -z "${DEVICE}" ]; then
    echo "test.sh: no device specified"
    help
    exit 1
fi

if [ ! -b "${DEVICE}" ]; then
echo REMAKING FILE
rm -f "${DEVICE}"
# dd if=/dev/zero of=${DEVICE} bs=512 count=1 seek=8388000  2> /dev/null #8388608
# dd if=/dev/zero of=${DEVICE} bs=512 count=1 seek=4194303 2> /dev/null
# dd if=/dev/zero of=${DEVICE} bs=512 count=1 seek=2097151 2> /dev/null
# dd if=/dev/zero of=${DEVICE} bs=512 count=1 seek=1050000 2> /dev/null
dd if=/dev/zero of=${DEVICE} bs=512 count=1 seek=10000 2> /dev/null # 5 MiB
chmod 666 ${DEVICE}
fi
# if [ ! -b "${DEVICE}" -a ! -f "${DEVICE}" ]; then
#    Need to parse ${END} to remove the trailing s if it exists, or if not, to change the bs units
#    dd if=/dev/zero of=${DEVICE} bs=512 count=1 seek=${END} status=noxfer 2> /dev/null
# fi

echo -n "zero overwrite partition table ... "
dd if=/dev/zero of=${DEVICE} bs=1024 count=256 status=noxfer conv=notrunc 2> /dev/null
echo "ok"

echo -n "create new partition table ... "
/sbin/parted --script ${DEVICE} mklabel msdos
echo "ok"

# if we do not do this, the old partition in /dev does not go away
echo -n "probe partition table ... "
/sbin/partprobe ${DEVICE}
echo "ok"

# This commented-out block of code is unreliable
# echo -n "wait for old partition to go ... "
# declare -i c
# c=0
# until [ ! -e ${DEVICE}1 ]; do
#     sleep 0.1
#     echo -n .
#     c=c+1
#     if [ ${c} -gt 10 ]; then
#         # sometimes it needs a harder whack
#         /sbin/partprobe -s > /dev/null 2> /dev/null
# 	sleep 0.1
#     fi
# done
# echo "ok"

echo -n "create new partition ... "
echo /sbin/parted --script -- ${DEVICE} mkpart primary ext2 1048576B ${END}
/sbin/parted --script -- ${DEVICE} mkpart primary ext2 1048576B ${END} || true
echo "ok"

if [ -b ${DEVICE} ] ; then 
    PARTITION=${DEVICE}1

    echo -n "wait for new partition to arrive ... "
    until [ -e ${PARTITION} ]; do sleep 0.1; echo -n .; done
    echo "ok"
else
    OFFSET=512
    PARTITION=`/sbin/losetup -o ${OFFSET} -f -s ${DEVICE}`
    echo partition = $PARTITION
fi

echo -n "make filesystem ... "
#/sbin/mke2fs -n -b 4096 -q ${PARTITION}
# /sbin/mke2fs -n -j -O dir_index,^huge_file -E resize=8G -m 1 -b 4096 -q ${PARTITION}
/sbin/mke2fs -j -O dir_index -m 1 -b 1024 -q ${PARTITION}
echo "made"

# we occasionally get
# mount: you must specify the filesystem type
# despite having just created the filesystem
echo -n "mount filesystem ... "
until mount ${PARTITION} /mnt; do sleep 0.1; done
echo "mounted"

echo "create test content"

mkdir /mnt/boot
cp ext2test.fth /mnt/boot/olpc.fth

pushd /mnt
touch touched
echo hello > hello
echo hello world > hello-world
md5sum hello-world > hello-world.md5
date > date
ln -s hello hello-link
mkdir directory
ln -s directory directory-link
touch directory/touched
echo hello world down here > directory/hw
mkfifo fifo
mknod node b 1 1
popd

if [ ! -b ${DEVICE} ] ; then 
    echo -n "save dirty journal ..."
    sleep 10
    cp ${DEVICE} ${DEVICE}.dirty
fi

echo -n "unmount ... "
umount /mnt
sync

if [ ! -b ${DEVICE} ] ; then 
   /sbin/losetup -d ${PARTITION}
   sync
   mv ${DEVICE} ${DEVICE}.clean
   cp ${DEVICE}.dirty ${DEVICE}.test
fi

echo "finished"
