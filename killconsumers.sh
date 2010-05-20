kill $(ps -ef | grep ruby | grep msgconsumer | grep -v grep | grep -v route | Cut -d' ' -f 4)
