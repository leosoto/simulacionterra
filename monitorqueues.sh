#|/bin/bash

while true; do 
    rabbitmqctl list_queues name messages messages_unacknowledged messages_ready
    sleep 1
done