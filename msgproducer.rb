#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'mq'
require 'optparse'
require 'simpleoptparse'

Signal.trap('INT') { AMQP.stop{ EM.stop } }
Signal.trap('TERM'){ AMQP.stop{ EM.stop } }

class NormalSample
  NV_MAGICCONST =  4 * Math.exp(-0.5) / Math.sqrt(2.0)
  
  def initialize(mu, sigma)
    @mu, @sigma = mu, sigma
  end

  def normalvariate
    # Ported from Python's random.normalvariate
    while true
      u1 = rand
      u2 = 1.0 - rand
      z = NV_MAGICCONST * (u1 - 0.5) / u2
      zz = z * z / 4.0
      break if zz <= -Math.log(u2)
    end
    @mu + z * @sigma
  end

  def next
    normalvariate
  end
end

class MsgProducer
  def initialize(host, queue_name, mps, sleep_time = 1,stddev = nil)
    @host, @queue_name = host, queue_name
    @mps_sample = NormalSample.new(mps, stddev || mps / 2)
    @sleep_time = sleep_time
    @total_messages_sent = 0
    @total_elapsed_seconds = 0
    @n_pending_messages_to_send_when_producing = 0
    @last_production_time = nil
  end

  def message
    raise NotImplementedError
  end

  def seconds_since_last_production!
    current_time = Time.now
    elapsed = current_time - @last_production_time
    @last_production_time = current_time
    elapsed
  end

  def produce
    elapsed_seconds = seconds_since_last_production!
    @total_elapsed_seconds += elapsed_seconds
    n_new_messages = @mps_sample.next
    @n_pending_messages_to_send_when_producing += n_new_messages * elapsed_seconds
    n_messages_to_send_now = @n_pending_messages_to_send_when_producing.round
    if n_messages_to_send_now > 0
      @n_pending_messages_to_send_when_producing -= n_messages_to_send_now
      @total_messages_sent += n_messages_to_send_now
      n_messages_to_send_now.times { publish(message) }
    end
    print_stats
  end

  def queue
    @queue ||= MQ.queue(@queue_name, :durable => true)
  end

  def publish(message)
    queue.publish message, :persistent => true, :mandatory => true
  end


  def should_print_stats?
    if @last_print_stat_time.nil? || Time.now - @last_print_stat_time > 5
      @last_print_stat_time = Time.now
      return true
    else
      false
    end
 end
  
  def print_stats
    return unless should_print_stats?
    puts
    puts "Process id: #{Process.pid}"
    puts "Total messages sent #{@total_messages_sent}"    
    puts "Seconds elapsed #{@total_elapsed_seconds}"
    puts "MPS: #{@total_messages_sent / @total_elapsed_seconds}"
  end

  def run
    puts "Producer started in process id #{Process.pid}"
    AMQP.start(:host => @host) do
      @last_production_time = Time.now
      EM.add_periodic_timer(@sleep_time) { produce }
    end
  end
end

class TestProducer < MsgProducer
  def initialize(host, queue_name, msg_len = 140, mps = 10, sleep_time = 1, stddev = nil)
    @msg_len_sample = NormalSample.new(msg_len, msg_len / 4)
    super(host, queue_name, mps, sleep_time, stddev)
  end

  def message
    <<EOM
    Destino: 123456789
    Carrier: Movistar
    Text: #{random_string(@msg_len_sample.next.to_i)}
    Process: #{Process.pid}
    Seq: #{next_seq_number}
EOM
  end

  def next_seq_number
    @next_seq_number ||= 0
    @next_seq_number += 1
  end

  def random_string(length)
    (1..length).map{ 65.+(rand(25)).chr}.join
  end
end

def main
  options = {}
  optparse = OptionParser.new do |opts|
    opts.simple('-m', '--mps MSGS_PER_SECOND', Integer, 
                'Mensajes por segundo promedio',
                :store_in => options, :as => :mps, :default => 10)
    opts.simple('-l', '--len MSG_LENGTH', Integer, 
                'Largo promedio de cada mensaje',
                :store_in => options, :as => :len, :default => 140)
    opts.simple('-q', '--queue NOMBRE', 'Nombre de la cola destino',
                :store_in => options, :as => :queue_name, 
                :default => 'router.req')
    opts.simple('-s', '--sleep SEGUNDOS', Integer, 
                'Tiempo de dormido entre envios de mensajes',
                :store_in => options, :as => :sleep_time, :default => 1)
    opts.simple('-h', '--host HOST', 'IP o nombre del servidor AMQP',
                :store_in => options, :as => :host, :default => 'localhost')
  end
  optparse.parse!  

  producer = TestProducer.new(options[:host], options[:queue_name], 
                              options[:len], 
                              options[:mps], options[:sleep_time])
  producer.run
end

main()

