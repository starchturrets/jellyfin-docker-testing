FROM alpine:latest AS build

# Install dependencies
RUN apk --no-cache add -u -f \
	curl \
	git \
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
RUN npm run build:production

WORKDIR /home/root
RUN mv /home/root/jellyfin-web/dist /home/root/dist/jellyfin/jellyfin-web

# Add minimal dependencies
FROM alpine:latest AS runtime

# Add hardened_malloc
COPY --from=ghcr.io/polarix-containers/hardened_malloc:latest /install /usr/local/lib/
ENV LD_PRELOAD="/usr/local/lib/libhardened_malloc.so"

RUN apk --no-cache add -u -f \
	ffmpeg \
	icu-libs \
	icu-data-full \
	libstdc++

# Default environment variables for the Jellyfin invocation
ENV DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    JELLYFIN_DATA_DIR="/config" \
    JELLYFIN_CACHE_DIR="/cache" \
    JELLYFIN_CONFIG_DIR="/config/config" \
    JELLYFIN_LOG_DIR="/config/log" \
    JELLYFIN_WEB_DIR="/jellyfin/jellyfin-web" \
    JELLYFIN_FFMPEG="/usr/bin/ffmpeg"
#   JELLYFIN_FFMPEG="/usr/lib/jellyfin-ffmpeg/ffmpeg"
COPY --from=build /home/root/dist /home/root/dist
ENTRYPOINT ["/home/root/dist/jellyfin/jellyfin"]

