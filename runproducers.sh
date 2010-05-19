if [ "$AMQPSERVER" == "" ] ; then
    AMQPSERVER=localhost
fi
QUEUE=router.req
echo "Iniciando productor de 20 MPS promedio, con envios constantes"
./msgproducer.rb -h $AMQPSERVER -q $QUEUE -s 0 --mps 20 &
sleep 1
echo "Iniciando productor de 20 MPS promedio, con envios cada 1 minuto"
./msgproducer.rb -h $AMQPSERVER -q $QUEUE -s 60 --mps 20 &
sleep 1
echo "Iniciando productor de 50 MPS promedio, con envios cada 5 minuto"
./msgproducer.rb -h $AMQPSERVER -q $QUEUE -s 300 --mps 50 &
sleep 1
