FROM centos:6

WORKDIR /root

RUN yum makecache && yum -y update && \
    yum install -y centos-release-scl epel-release && \
    yum install -y devtoolset-6 dnf install libcurl-devel openssl-devel \
    libuuid-devel pulseaudio-devel git rpm-build \
    libmaxminddb-devel libmaxminddb

# Use devtoolset-6
ENV PERL5LIB='PERL5LIB=/opt/rh/devtoolset-6/root/usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-6/root/usr/lib/perl5:/opt/rh/devtoolset-6/root//usr/share/perl5/vendor_perl' \
    X_SCLS=devtoolset-6 \
    PCP_DIR=/opt/rh/devtoolset-6/root \
    LD_LIBRARY_PATH=/opt/rh/devtoolset-6/root/usr/lib64:/opt/rh/devtoolset-6/root/usr/lib \
    PATH=/opt/rh/devtoolset-6/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PYTHONPATH=/opt/rh/devtoolset-6/root/usr/lib64/python2.7/site-packages:/opt/rh/devtoolset-6/root/usr/lib/python2.7/site-packages \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

RUN curl -OL https://github.com/aws/aws-sdk-cpp/archive/1.3.7.tar.gz && \
    if [[ `sha256sum 1.3.7.tar.gz | awk '{print $1}'` != \
        "fa602dcfe65561986a9359772bb0446a657f90bbc8d84d5d8e22eb028df84bee" ]]; then exit 1; fi && \
    curl -OL https://cmake.org/files/v3.10/cmake-3.10.2-Linux-x86_64.tar.gz && \
    if [[ `sha256sum cmake-3.10.2-Linux-x86_64.tar.gz | awk '{print $1}'` != \
        "7a82b46c35f4e68a0807e8dc04e779dee3f36cd42c6387fd13b5c29fe62a69ea" ]]; then exit 1; fi && \
    (cd /usr && tar --strip-components=1 -zxf /root/cmake-3.10.2-Linux-x86_64.tar.gz) && \
    tar -zxf 1.3.7.tar.gz && mkdir -p aws-sdk-cpp-1.3.7/release && cd aws-sdk-cpp-1.3.7/release && \
    cmake -DBUILD_ONLY="kinesis;monitoring;identity-management;sts;cognito-identity" \
    -DBUILD_SHARED_LIBS=OFF .. && make && make install

RUN git clone https://github.com/mozilla-services/lua_sandbox && \
    git clone https://github.com/mozilla-services/hindsight && \
    mkdir -p lua_sandbox/release && cd lua_sandbox/release && \
    cmake -DCMAKE_BUILD_TYPE=release .. && \
    make && ctest && cpack -G RPM && rpm -i *.rpm && cd ../.. && \
    mkdir -p hindsight/release && cd hindsight/release && \
    cmake -DCMAKE_BUILD_TYPE=release .. && \
    make && ctest && cpack -G RPM && rpm -i *.rpm

RUN git clone https://github.com/mozilla-services/lua_sandbox_extensions && \
    mkdir -p lua_sandbox_extensions/release && cd lua_sandbox_extensions/release && \
    cmake -DCMAKE_BUILD_TYPE=release -DCPACK_GENERATOR=RPM \
    -DEXT_aws=on -DEXT_syslog=on -DEXT_socket=on -DEXT_lpeg=on -DEXT_heka=on -DEXT_cjson=on \
    -DEXT_lfs=on -DEXT_maxminddb=on .. && \
    make && ctest -V && make packages && rpm -i *.rpm

RUN mkdir dist && cp lua_sandbox_extensions/release/*.rpm dist/ && \
    cp hindsight/release/*.rpm dist/ && \
    cp lua_sandbox/release/*.rpm dist/
