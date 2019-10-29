FROM google/dart:2.5.0

RUN apt-get update -qq
RUN apt-get update && apt-get install -y \
	wget \
	&& rm -rf /var/lib/apt/lists/*

# install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -qq update && apt-get install -y google-chrome-stable
RUN mv /usr/bin/google-chrome-stable /usr/bin/google-chrome
RUN sed -i --follow-symlinks -e 's/\"\$HERE\/chrome\"/\"\$HERE\/chrome\" --no-sandbox/g' /usr/bin/google-chrome

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
	dart --version && \
	pub get && \
    pub run dependency_validator && \
	pub run dart_dev format --check && \
	pub run dart_dev analyze && \
	pub run dart_dev test --release && \

	# make a temp location to run pub publish dry run so it only looks at what is published
	# otherwise it fails with "Your package is 232.8 MB. Hosted packages must be smaller than 100 MB."
	tar czvf font_face_observer.pub.tgz LICENSE README.md pubspec.yaml analysis_options.yaml lib/ && \
	mkdir .temp && \
	tar xzvf font_face_observer.pub.tgz -C .temp && \
	cd .temp && \
	pub publish --dry-run && \
	cd .. && \

	dartdoc && \
	tar czvf api.tar.gz -C doc/api .

ARG BUILD_ARTIFACTS_DOCUMENTATION=/build/api.tar.gz
ARG BUILD_ARTIFACTS_DART-DEPENDENCIES=/build/pubspec.lock
ARG BUILD_ARTIFACTS_PUB=/build/font_face_observer.pub.tgz

FROM scratch
