# Jellyfin

This is an experimental docker image of jellyfin, patched to be compatible with gvisor for my own personal use. As I am using it on a server without a GPU, I have not added in the support for it as [upstream](https://github.com/jellyfin/jellyfin-packaging/blob/master/docker/Dockerfile) has. Also, the default ffmpeg from alpine is used instead of jellyfin-ffmpeg. The container should rebuild daily (but github keeps stopping the builds).

