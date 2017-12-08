FROM ubuntu:17.10

# Dependencies to execute android
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -q \
    && apt-get install -y openjdk-8-jdk wget expect git curl unzip vim \
    && apt-get install -y kvm qemu-kvm libvirt-bin bridge-utils libguestfs-tools \
    && apt-get clean

# Main Android SDK
RUN mkdir -p /opt/android/
RUN cd /opt/android && wget -q https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
RUN cd /opt/android && unzip sdk-tools-linux-3859397.zip
RUN cd /opt/android && rm -f sdk-tools-linux-3859397.zip

ENV ANDROID_SDK_HOME /opt/android/
ENV ANDROID_SDK_ROOT /opt/android/
ENV ANDROID_HOME /opt/android/
ENV ANDROID_SDK /opt/android/

# Other tools and resources of Android SDK
ENV PATH ${PATH}:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

RUN yes | sdkmanager --licenses
RUN sdkmanager --channel=0 "system-images;android-27;google_apis_playstore;x86" "platforms;android-27" "platform-tools" "tools" "emulator"

# Cleaning
RUN apt-get clean

# Set up and run emulator
RUN echo no | avdmanager create avd --force -n test -k "system-images;android-27;google_apis_playstore;x86" --device "3.2in QVGA (ADP2)"

# Avoid emulator assumes HOME as '/'.
ENV HOME /root
ADD wait-for-emulator.sh /usr/local/bin/
ADD kvm.sh /usr/local/bin/

CMD lsmod && kvm.sh \ 
      &&$ {ANDROID_HOME}/emulator/emulator -avd test -no-audio -netfast -no-window  \
      && wait-for-emulator.sh \
      && cd /code/zendesk_sdk_android  \
      && ./gradlew :EspressoTestApp:cADT

