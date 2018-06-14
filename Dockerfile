FROM drydock-prod.workiva.net/workiva/smithy-runner-generator:313742 as build

# Build Environment Vars
ARG BUILD_ID
ARG BUILD_NUMBER
ARG BUILD_URL
ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GIT_TAG
ARG GIT_COMMIT_RANGE
ARG GIT_HEAD_URL
ARG GIT_MERGE_HEAD
ARG GIT_MERGE_BRANCH
WORKDIR /build/
ADD . /build/
ENV CODECOV_TOKEN='bQ4MgjJ0G2Y73v8JNX6L7yMK9679nbYB'
RUN echo "Starting the script sections" && \
	wget https://storage.googleapis.com/dart-archive/channels/dev/release/2.0.0-dev.62.0/sdk/dartsdk-linux-x64-release.zip && \
	unzip dartsdk-linux-x64-release.zip && \
	export D2PATH=`pwd`/dart-sdk/bin && \
	# Start with Dart 1
	dart --version && \
	pub --version && \
	pub get && \
	pub run dart_dev analyze && \
	xvfb-run -s '-screen 0 1024x768x24' pub run dart_dev test --web-compiler=dartdevc -p chrome && \
	# Switch to Dart 2
	export PATH=$D2PATH:$PATH && \
	dart --version && \
	pub --version && \
	pub get && \
	pub run dart_dev analyze && \
	pub run dart_dev format --check && \
	xvfb-run -s '-screen 0 1024x768x24' pub run dart_dev test --web-compiler=dartdevc -p chrome && \
	pub run dart_dev docs --no-open && \
	tar czvf api.tar.gz -C doc/api . && \
	pub run dart_build build test && \
	./tool/stage_for_cdn.sh && \
	tar -hcf build.tar.gz build/test/ && \
	tar czvf font_face_observer.pub.tgz LICENSE README.md pubspec.yaml analysis_options.yaml lib/ && \
	#./tool/codecov.sh && \
	mkdir .temp && \
	tar xzvf font_face_observer.pub.tgz -C .temp && \
	cd .temp && \
	pub publish --dry-run && \
	echo "Script sections completed"
ARG BUILD_ARTIFACTS_WEB_BUILD=/build/build.tar.gz
ARG BUILD_ARTIFACTS_DOCUMENTATION=/build/api.tar.gz
ARG BUILD_ARTIFACTS_DART-DEPENDENCIES=/build/pubspec.lock
ARG BUILD_ARTIFACTS_PUB=/build/font_face_observer.pub.tgz
FROM scratch
