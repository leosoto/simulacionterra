kill $(ps -ef | grep ruby | grep msgconsumer | grep route | grep -v grep |  cut -d' ' -f 4)
