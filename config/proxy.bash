# >>> proxy setting >>>
proxy () {
        export ALL_PROXY="http://192.168.1.10:7890"
        export all_proxy="http://192.168.1.10:7890"
        export http_proxy="http://192.168.1.10:7890"
        export https_proxy="http://192.168.1.10:7890"
#        echo -e "Acquire::http::Proxy \"http://192.168.123.176:10809\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
#        echo -e "Acquire::https::Proxy \"http://192.168.123.176:10809\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
        curl myip.ipip.net
        }

noproxy () {
        unset ALL_PROXY
        unset all_proxy
#        sudo sed -i -e '/Acquire::http::Proxy/d' /etc/apt/apt.conf
#        sudo sed -i -e '/Acquire::https::Proxy/d' /etc/apt/apt.conf
        curl myip.ipip.net
        }
# <<< proxy setting <<<
