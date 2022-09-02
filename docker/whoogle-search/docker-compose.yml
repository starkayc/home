```version: "3"
services:
#---------------------------------------------------------------------------------------------------------------------------------#
#                         whoogle-search - A self-hosted, ad-free, privacy-respecting metasearch engine                           #
#---------------------------------------------------------------------------------------------------------------------------------#
  whoogle-search:
    image: benbusby/whoogle-search
    container_name: whoogle
    hostname: whoogle-search
    restart: unless-stopped
    ports:
      - "8200:5000"
    environment:
      - PUID=1026
      - PGID=100
      - TZ=America/New_York
```
