#/bin/bash

HOSTROOT=`pwd`
DOCKERROOT=/root

PORTDIR=$1
PORTNAME=`basename $PORTDIR`
SRCDIR=$PORTDIR/src
SETUPSCRIPT=$SRCDIR/docker-setup.txt
PRODUCTSCRIPT=$SRCDIR/retrieve-products.txt
BUILDSCRIPT=$SRCDIR/build.txt

BUILDDIR=build-port

mkdir -p $HOSTROOT/$BUILDDIR
cd $HOSTROOT/$BUILDDIR
cp $HOSTROOT/$SRCDIR/* .

# Use 'bash' to run the script instead of direct execution
bash $HOSTROOT/$SETUPSCRIPT $PORTNAME-build

sleep 5

docker exec -e FORCE_HEAD=${FORCE_HEAD:-false} $PORTNAME-build /bin/bash -c "cd $BUILDDIR && bash $DOCKERROOT/$BUILDSCRIPT"

bash $HOSTROOT/$PRODUCTSCRIPT $HOSTROOT/$BUILDDIR $HOSTROOT/$PORTDIR