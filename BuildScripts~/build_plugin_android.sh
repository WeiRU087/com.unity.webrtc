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
  cmake . \
    -B build \
    -D CMAKE_SYSTEM_NAME=Android \
    -D CMAKE_ANDROID_API_MIN=24 \
    -D CMAKE_ANDROID_API=24 \
    -D CMAKE_ANDROID_ARCH_ABI=$ARCH_ABI \
    -D CMAKE_ANDROID_NDK=$ANDROID_NDK \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_ANDROID_STL_TYPE=c++_static

  cmake \
    --build build \
    --target WebRTCPlugin

  echo $(pwd)
  mkdir -p $PLUGIN_DIR/jni/$ARCH_ABI
  mv $PLUGIN_DIR/libwebrtc.so $PLUGIN_DIR/jni/$ARCH_ABI

  echo "\n----- Cmake build for $ARCH_ABI done -----\n\n"
done


# libwebrtc.so move into libwebrtc.aar
cp -f $SOLUTION_DIR/webrtc/lib/libwebrtc.aar $PLUGIN_DIR
pushd $PLUGIN_DIR
zip -g libwebrtc.aar jni/armeabi-v7a/libwebrtc.so jni/arm64-v8a/libwebrtc.so jni/x86_64/libwebrtc.so
rm -r jni
popd
