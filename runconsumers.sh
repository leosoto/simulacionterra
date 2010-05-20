#!/bin/bash
if [ "$AMQPSERVER" == "" ]; then
    AMQPSERVER=localhost
fi
echo "Iniciando 3 consumidores finales con tiempo de procesamiento de 0.03 segundos"
./msgconsumer.rb -h $AMQPSERVER -q router.resp.canal1 -p 0.03 > log-consumidor-canal1.txt &
./msgconsumer.rb -h $AMQPSERVER -q router.resp.canal2 -p 0.03 > log-consumidor-canal2.txt &
./msgconsumer.rb -h $AMQPSERVER -q router.resp.canal3 -p 0.03 > log-consumidor-canal3.txt &
