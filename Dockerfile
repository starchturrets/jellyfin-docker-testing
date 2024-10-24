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

# Dependencies?
FROM alpine:latest AS runtime
RUN apk --no-cache add -u -f \
	lsb-release \
	libssl*.* \
	liblttng-ust*\
	libssl-dev \
	libfontconfig*-dev \
	libcurl*openssl-dev \
	libfreetype-dev \
	ffmpeg \
	icu-libs \
	icu-data-full


#	dotnet8-runtime
COPY --from=build /home/root/dist /home/root/dist

ENTRYPOINT ["/home/root/dist/jellyfin/jellyfin"]

