# >>> proxy setting >>>
# alias hp="http_proxy=http://127.0.0.1:1081 https_proxy=http://127.0.0.1:1081"

PROXY_IP=192.168.3.151:1081
alias hp="http_proxy=http://$PROXY_IP https_proxy=http://$PROXY_IP"
proxy () {
        export ALL_PROXY="$PROXY_IP"
        export all_proxy="$PROXY_IP"
        export http_proxy="$PROXY_IP"
        export HTTP_PROXY="$PROXY_IP"
        export https_proxy="$PROXY_IP"
        export HTTPS_PROXY="$PROXY_IP"

#        echo -e "Acquire::http::Proxy \"http://192.168.123.176:10809\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
#        echo -e "Acquire::https::Proxy \"http://192.168.123.176:10809\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
        curl myip.ipip.net
        }

noproxy () {
        unset ALL_PROXY
        unset all_proxy
        unset http_proxy
        unset HTTP_PROXY
        unset https_proxy
        unset HTTPS_PROXY

        unset all_proxy
        unset http_proxy
        unset https_proxy
#        sudo sed -i -e '/Acquire::http::Proxy/d' /etc/apt/apt.conf
#        sudo sed -i -e '/Acquire::https::Proxy/d' /etc/apt/apt.conf
        curl myip.ipip.net
        }
# <<< proxy setting <<<
