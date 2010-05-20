#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'mq'
require 'optparse'
require 'simpleoptparse'
require 'seconds_as_minutes_string'

Signal.trap('INT') { AMQP.stop{ EM.stop } }
Signal.trap('TERM'){ AMQP.stop{ EM.stop } }


class MsgConsumer
  def initialize(host, queue_name, process_time = 0.05)
    @host, @queue_name, @process_time = host, queue_name, process_time
    @total_messages_received = 0
    @last_print_stat_time = nil
    @start_time = nil
  end

  def should_print_stats?
    if @last_print_stat_time.nil? || Time.now - @last_print_stat_time > 5
      @last_print_stat_time = Time.now
      return true
    else
      false
    end
 end
  
  def print_stats(msg)
    return unless should_print_stats?
    puts
    puts "Process id: #{Process.pid}"
    puts "Time: #{Time.now.strftime('%H:%M:%S')}"
    puts "Total messages received: #{@total_messages_received}"    
    puts "Minutes elapsed: #{(Time.now - @start_time).seconds_as_minutes_string}"
    puts "MPS: #{@total_messages_received / (Time.now - @start_time)}"
    puts "Last message: \n#{msg}"
  end

  def process(msg)
    sleep @process_time
    print_stats(msg)
  end

  def run
    puts "Consumer started in process id #{Process.pid}"
    AMQP.start(:host => @host) do
      @start_time = Time.now
      queue = MQ.queue(@queue_name, :durable => true)
      queue.pop(:ack => true) do |h, msg|
        if msg
          process msg
          @total_messages_received += 1
          h.ack
          queue.pop
        else
          EM.add_timer(1) { queue.pop }
        end
      end
    end
  end
end

class MsgRouter < MsgConsumer
  def initialize(host, src_queue_name, dst_queue_names, process_time = 0.05)
    @dst_queue_names = dst_queue_names
    @dst_queues = {}
    super(host, src_queue_name, process_time)
  end

  def process(msg)
    super    
    random_destination_queue.publish(msg, :persistent => true, :mandatory => true)
  end

  def random_destination_queue
    queue_name = @dst_queue_names[rand(@dst_queue_names.length)]
    @dst_queues[queue_name] ||= MQ.new.queue(queue_name)
  end
end

def main
  options = {}
  optparse = OptionParser.new do |opts|
    opts.simple('-q', '--queue NAME', 
                'Nombre de la cola destino', 
                :store_in => options, :as => :queue_name,  
                :default => 'router.req')
    opts.simple('-p', '--process SECONDS', Float, 
                'Tiempo de procesado de cada mensaje',
                :store_in => options, :as => :process_time, :default => 0.05)
    opts.simple('-h', '--host HOST', 
                'IP o nombre del servidor AMQP',
                :store_in => options, :as => :host, :default => 'localhost')
    opts.simple_flag('-r', '--route', 
                     'Indica que el consumidor debe rutear los mensajes a otras colas',
                     :store_in => options, :as => :route)
    opts.simple('-d', '--destination QUEUES', 
                'Colas de destino para el caso en que el consumidor rutea, separadas por espacios',
                :store_in => options, :as => :destination_queues,
                :default => 'router.resp.canal1 router.resp.canal2 router.resp.canal3')
  end
  optparse.parse!  

  if options[:route]    
    consumer = MsgRouter.new(options[:host], options[:queue_name], 
                             options[:destination_queues].split, 
                             options[:process_time])
  else
    consumer = MsgConsumer.new(options[:host], options[:queue_name], 
                               options[:process_time])
  end
  consumer.run
end

main()

