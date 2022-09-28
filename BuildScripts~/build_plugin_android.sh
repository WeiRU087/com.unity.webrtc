#!/bin/bash -eu

export LIBWEBRTC_DOWNLOAD_URL=https://github.com/WeiRU087/com.unity.webrtc/releases/download/M92/M92_webrtc-android_x64_arm64_armv7a.zip
export SOLUTION_DIR=$(pwd)/Plugin~
export PLUGIN_DIR=$(pwd)/Runtime/Plugins/Android
# export ARCH_ABI=arm64-v8a

# Download LibWebRTC 
curl -L $LIBWEBRTC_DOWNLOAD_URL > webrtc.zip
unzip -d $SOLUTION_DIR/webrtc webrtc.zip 

# Build UnityRenderStreaming Plugin 
cd "$SOLUTION_DIR"

for ARCH_ABI in armeabi-v7a arm64-v8a x86_64
do
  cd "$SOLUTION_DIR"
  build_dir=build/$ARCH_ABI
  cmake . \
    -B $build_dir \
    -D CMAKE_SYSTEM_NAME=Android \
    -D CMAKE_ANDROID_API_MIN=24 \
    -D CMAKE_ANDROID_API=24 \
    -D CMAKE_ANDROID_ARCH_ABI=$ARCH_ABI \
    -D CMAKE_ANDROID_NDK=$ANDROID_NDK \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_ANDROID_STL_TYPE=c++_static

  cmake \
    --build $build_dir \
    --target WebRTCPlugin || printf "\nlink failed but ignore\n"

  if [ -e "$PLUGIN_DIR/libwebrtc.so" ]; then
    mkdir -p $PLUGIN_DIR/jni/$ARCH_ABI
    mv $PLUGIN_DIR/libwebrtc.so $PLUGIN_DIR/jni/$ARCH_ABI/libwebrtc.so
    echo "build success"
  else
    echo "build failed"

    cd "$SOLUTION_DIR/$build_dir/WebRTCPlugin"
    printf "\n    $(pwd)\n"
    cat ./CMakeFiles/WebRTCPlugin.dir/link.txt > ./CMakeFiles/WebRTCPlugin.dir/link.txt.bak
    sed -i 's/--require-defined=[^[:space:]]* -Wl,//g' ./CMakeFiles/WebRTCPlugin.dir/link.txt

    cmake -E cmake_link_script CMakeFiles/WebRTCPlugin.dir/link.txt --verbose=1 || echo "link failed but ignore--------------"

    cd "$SOLUTION_DIR"

    echo $(pwd)
    mkdir -p $PLUGIN_DIR/jni/$ARCH_ABI
    mv $PLUGIN_DIR/libwebrtc.so $PLUGIN_DIR/jni/$ARCH_ABI/libwebrtc.so || printf "$PLUGIN_DIR/libwebrtc.so not found\n"
  fi

  printf "\n----- Cmake build for $ARCH_ABI done -----\n\n"
done


# libwebrtc.so move into libwebrtc.aar
cp -f $SOLUTION_DIR/webrtc/lib/libwebrtc.aar $PLUGIN_DIR
pushd $PLUGIN_DIR
zip -g libwebrtc.aar jni/armeabi-v7a/libwebrtc.so jni/arm64-v8a/libwebrtc.so jni/x86_64/libwebrtc.so
rm -r jni
popd
