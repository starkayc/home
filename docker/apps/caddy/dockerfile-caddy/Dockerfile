FROM caddy:2.10.0-builder AS builder

RUN xcaddy build \
	--with github.com/caddy-dns/cloudflare \
	--with github.com/WeidiDeng/caddy-cloudflare-ip \
	--with github.com/hslatman/caddy-crowdsec-bouncer/http@main \
	--with github.com/hslatman/caddy-crowdsec-bouncer/layer4@main \
	--with github.com/hslatman/caddy-crowdsec-bouncer/appsec
FROM caddy:2.10.0

COPY --from=builder /usr/bin/caddy /usr/bin/caddy