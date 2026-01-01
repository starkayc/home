*.local.{$DOMAIN} {
	crowdsec
	import ../tls/example.com
	import wildcards-example.com
	import ../headers/default.conf
        log {
                output discard
        }