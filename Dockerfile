FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
  openjdk-17-jdk \
  python3 \
  python3-pip \
  curl \
  bash \
  git \
  nodejs \
  npm \
  supercollider \
  && apt-get clean

WORKDIR /app

COPY . .

RUN find . -name "*.java" > sources.txt && javac @sources.txt || true

RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt || true

ENTRYPOINT ["bash", "scripts/install.sh"]
