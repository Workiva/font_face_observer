FROM google/dart:2
WORKDIR /build/
ADD pubspec.yaml /build
RUN pub get && pub run test --no-chain-stack-traces -p vm -p chrome --reporter=expanded
FROM scratch
