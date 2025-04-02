i.example.moe example.lol example.lol {
        crowdsec
        file_server
        encode zstd gzip
        import ../headers/default.conf
        import ../tls/cloudflare.conf
        reverse_proxy localhost:3000
                request_body {
                max_size 250MB
        }
        log {
                output file /var/log/caddy/zipline.log {
                        roll_size 10mb
                        roll_keep 20
                        roll_keep_for 720h
                }
        }
}