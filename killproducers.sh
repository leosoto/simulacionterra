kill $(ps -ef | grep ruby | grep msgproducer | grep -v grep | cut -d' ' -f 4)
