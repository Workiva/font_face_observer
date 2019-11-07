FROM drydock-prod.workiva.net/workiva/dart2_base_image:1 as build
WORKDIR /build/
ADD pubspec.yaml /build
RUN pub get
ADD . /build/

RUN dartdoc
RUN tar czvf api.tar.gz -C doc/api .
RUN tar czvf font_face_observer.pub.tgz LICENSE README.md pubspec.yaml analysis_options.yaml lib/

ARG BUILD_ARTIFACTS_DOCUMENTATION=/build/api.tar.gz
ARG BUILD_ARTIFACTS_PUB=/build/font_face_observer.pub.tgz
FROM scratch
