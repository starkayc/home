```version: "3"
#--------------------------------------------------------------------------------------------#
#             Gitea - Git with a cup of tea, painless self-hosted git service                #
#--------------------------------------------------------------------------------------------#
networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.16.8
    container_name: gitea
    environment:
      - USER_UID=1026
      - USER_GID=100
      - TZ=America/New_York
    restart: always
    networks:
      - gitea
    volumes:
      - /volume1/docker/gitea:/data
    ports:
      - "3000:3000"
      - "222:22"
```