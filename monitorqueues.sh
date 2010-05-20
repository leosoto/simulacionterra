#|/bin/bash

(while true; do
    echo
    date
    rabbitmqctl list_queues name messages messages_unacknowledged messages_ready memory
    sleep 1
done) > log-queue-status.txt