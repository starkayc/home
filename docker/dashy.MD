version: "3.8"
services:
#--------------------------------------------------------------------------------------------#
#                          Dashy - The Ultimate Homepage for your Homelab                    #
#--------------------------------------------------------------------------------------------#
  dashy:
    image: lissy93/dashy
    container_name: Dashy
    volumes:
      - /volume1/docker/dashy/conf.yml:/app/public/conf.yml

    ports:
      - 4000:80
    environment:
      - NODE_ENV=production
      - UID=1026
      - GID=100
    restart: unless-stopped
    healthcheck:
      test: ['CMD', 'node', '/app/services/healthcheck']
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
