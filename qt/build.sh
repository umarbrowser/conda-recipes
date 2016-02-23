#!/bin/bash

# Compile
# -------
if [ `uname` == Linux ]; then
    chmod +x configure

    if [ $ARCH == 64 ]; then
        MARCH=x86-64
    else
        MARCH=i686
    fi

    # Building QtWebKit on CentOS 5 fails without setting these flags
    # explicitly. This is caused by using an old gcc version
    # See https://bugs.webkit.org/show_bug.cgi?id=25836#c5
    CFLAGS="-march=${MARCH}" CXXFLAGS="-march=${MARCH}" \
    CPPFLAGS="-march=${MARCH}" LDFLAGS="-march=${MARCH}" \
    ./configure -prefix $PREFIX \
                -libdir $PREFIX/lib \
                -bindir $PREFIX/lib/qt4/bin \
                -headerdir $PREFIX/include/qt4 \
                -datadir $PREFIX/share/qt4 \
                -L $PREFIX/lib \
                -I $PREFIX/include \
                -release \
                -fast \
                -no-qt3support \
                -nomake examples \
                -nomake demos \
                -nomake docs \
                -opensource \
                -verbose \
                -openssl \
                -webkit \
                -gtkstyle \
                -dbus \
                -system-libpng \
                -system-zlib

    # Build on RPM based distros fails without setting LD_LIBRARY_PATH
    # to the build lib dir
    # See https://bugreports.qt.io/browse/QTBUG-5385
    LD_LIBRARY_PATH=$SRC_DIR/lib make -j $CPU_COUNT
    
    make install

    cp $SRC_DIR/bin/* $PREFIX/bin/
    cd $PREFIX
    rm -rf doc phrasebooks q3porting.xml translations
    rm -rf demos examples
    cd $PREFIX/bin
    rm -f *.bat *.pl qt3to4 qdoc3
fi

if [ `uname` == Darwin ]; then
    # Leave Qt set its own flags and vars, else compilation errors
    # will occur
    for x in OSX_ARCH CFLAGS CXXFLAGS LDFLAGS
    do
	unset $x
    done

    chmod +x configure
    ./configure \
        -release -fast -prefix $PREFIX -platform macx-g++ \
        -no-qt3support -nomake examples -nomake demos -nomake docs \
        -opensource -verbose -openssl -no-framework -system-libpng \
        -arch `uname -m` -L $PREFIX/lib -I $PREFIX/include

    make -j $(sysctl -n hw.ncpu)
    make install
fi


# Post build setup
# ----------------
BIN=$PREFIX/lib/qt4/bin
QTCONF=$BIN/qt.conf

# Remove binaries that can't be present in $PREFIX/bin
pushd $PREFIX/bin
rm -f assistant designer lconvert linguist lrelease lupdate \
      moc pixeltool qcollectiongenerator qdbuscpp2xml \
      qdbus qdbusviewer qdbusxml2cpp qdoc3 qhelpconverter \
      qhelpgenerator qmake qmlplugindump qmlviewer qt3to4 \
      qtconfig qttracereplay rcc uic xmlpatterns \
      xmlpatternsvalidator
popd

# Make symlinks of binaries in $BIN to $PREFIX/bin
for file in $BIN/*
do
    ln -sfv ../lib/qt4/bin/$(basename $file) $PREFIX/bin/$(basename $file)-qt4
done

# Removes doc, phrasebooks, and translations
rm -rf $PREFIX/share/qt4

# Add qt.conf file to the package to make it fully relocatable
cat <<EOF >$QTCONF
[Paths]
Prefix = $PREFIX/lib/qt4
Libraries = $PREFIX/lib
Headers = $PREFIX/include/qt4

EOF
