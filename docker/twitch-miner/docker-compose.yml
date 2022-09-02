```version: "3.9"
services:
#--------------------------------------------------------------------------------------------------------------------#
#          Twitch Channel Points Miner v2 - A script that watch streams for you and earns channel points.            #
#--------------------------------------------------------------------------------------------------------------------#
  miner:
    container_name: tcpmv2
    image: tkdalex/twitch-channel-points-miner-v2
    tty: true
    environment:
      - TERM=xterm-256color
    volumes:
      - /volume1/docker/twitch/analytics:/usr/src/app/analytics
      - /volume1/docker/twitch/cookies:/usr/src/app/cookies
      - /volume1/docker/twitch/logs:/usr/src/app/logs
      - /volume1/docker/twitch/run.py:/usr/src/app/run.py:ro
    ports:
      - "7001:7001"
```