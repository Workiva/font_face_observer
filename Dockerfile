FROM drydock-prod.workiva.net/workiva/smithy-runner-generator:355624 as build

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
	wget https://storage.googleapis.com/dart-archive/channels/dev/release/2.0.0-dev.69.4/sdk/dartsdk-linux-x64-release.zip && \
	unzip dartsdk-linux-x64-release.zip && \
	export D2PATH=`pwd`/dart-sdk/bin && \
	# Start with Dart 1
	dart --version && \
	pub --version && \
	pub get && \
	# make a temp location to run pub publish dry run so it only looks at what is published
	# otherwise it fails with "Your package is 232.8 MB. Hosted packages must be smaller than 100 MB."
	tar czvf font_face_observer.pub.tgz LICENSE README.md pubspec.yaml analysis_options.yaml lib/ && \
	mkdir .temp && \
	tar xzvf font_face_observer.pub.tgz -C .temp && \
	cd .temp && \
	pub publish --dry-run && \
	cd .. && \
	dartanalyzer lib && \
	xvfb-run -s '-screen 0 1024x768x24' pub run test test/*_test.dart -p chrome && \
	# Switch to Dart 2
	alias pubcleanlock='git ls-files pubspec.lock --error-unmatch &>/dev/null && echo "Not removing pubspec.lock - it is tracked" || (rm pubspec.lock && echo "Removed pubspec.lock")' && \
	alias pubclean='rm -r .pub .dart_tool/pub && echo "Removed .pub/"; find . -name packages | xargs rm -rf && echo "Removed packages/"; rm .packages && echo "Removed .packages"; pubcleanlock' && \
	export PATH=$D2PATH:$PATH && \
	dart --version && \
	pub --version && \
	puclean && \
	pub get && \
	dartanalyzer . && \
	dartfmt -w --set-exit-if-changed && \
	xvfb-run -s '-screen 0 1024x768x24' pub run build_runner test -- test/*_test.dart -p chrome && \
	dartdoc && \
	tar czvf api.tar.gz -C doc/api . && \
	pub run dart_build build test && \
	./tool/stage_for_cdn.sh && \
	tar -hcf build.tar.gz build/test/ && \
	echo "Script sections completed"
ARG BUILD_ARTIFACTS_WEB_BUILD=/build/build.tar.gz
ARG BUILD_ARTIFACTS_DOCUMENTATION=/build/api.tar.gz
ARG BUILD_ARTIFACTS_DART-DEPENDENCIES=/build/pubspec.lock
ARG BUILD_ARTIFACTS_PUB=/build/font_face_observer.pub.tgz
FROM scratch
