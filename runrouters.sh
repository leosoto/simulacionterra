#!/bin/bash
if [ "$AMQPSERVER" == "" ] ; then
    AMQPSERVER=localhost
fi
QUEUE=router.req
echo "Iniciando 10 enrutadores con tiempo de procesamiento de 0.1 segundos"
for i in {1..10}; do 
   ./msgconsumer.rb \
       -h $AMQPSERVER -q $QUEUE -p 0.1 \
       --route -d "router.resp.canal1 router.resp.canal2 router.resp.canal3" \
       > log-router-$i.txt &
done

