	@dozzle host nas-dozzle.local.{$DOMAIN}
	handle @dozzle {
		reverse_proxy dozzle:8080
	}
	@ddns host ddns.local.{$DOMAIN}
	handle @ddns {
		reverse_proxy ddns-updater:8000
	}
	@scrutiny host scrutiny.local.{$DOMAIN}
	handle @scrutiny {
		reverse_proxy scrutiny:8080
	}
	@syncthing host syncthing.local.{$DOMAIN}
	handle @syncthing {
		reverse_proxy 172.19.0.1:8384
	}
	@wud host nas-wud.local.{$DOMAIN}
	handle @wud {
		reverse_proxy wud:3000
	}