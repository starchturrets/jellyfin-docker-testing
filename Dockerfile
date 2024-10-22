FROM alpine:latest

# Install dependencies
RUN apk --no-cache add -u -f \
	wget \
	curl \
	unzip \
	git \
	debhelper \
	gnupg \
	devscripts \
	build-essential \
	mmv \ 
	lsb-release \
	zip \
	libssl*.* \
	liblttng-ust*\
	libssl-dev \
	libfontconfig*-dev \
	libcurl*openssl-dev \
	libfreetype-dev \
	dotnet8-sdk \
	nodejs \
	npm \ 
	ffmpeg

# Fetch jellyfin and jellyfin-web

WORKDIR /home/root
RUN git clone https://github.com/jellyfin/jellyfin.git
RUN mv jellyfin jellyfin-server
RUN git clone https://github.com/jellyfin/jellyfin-web.git

# Patch jellyfin-server

RUN sed -i '/^\s*NetworkChange\.Network/d' jellyfin-server/src/Jellyfin.Networking/Manager/NetworkManager.cs
RUN dotnet publish jellyfin-server/Jellyfin.Server --configuration Release --self-contained --runtime linux-musl-x64 --output /home/root/dist/jellyfin -p:DebugSymbols=false -p:DebugType=none -p:UseAppHost=true

# Build jellyfin-web
WORKDIR /home/root/jellyfin-web
RUN npm ci --no-audit --unsafe-perm
RUN npx depcheck
RUN npm run build:production

WORKDIR /home/root
RUN mv /home/root/jellyfin-web/dist /home/root/dist/jellyfin/jellyfin-web


ENTRYPOINT ["/home/root/dist/jellyfin/jellyfin"]

#ENTRYPOINT ["/bin/sh"]

