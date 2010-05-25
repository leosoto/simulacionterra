import parser
import plotter
import glob
from matplotlib import pyplot

def parse_logs(test_name, component):
    return [parser.parse_log(file(f))
            for f in glob.glob('%s/log-%s-*' % (test_name, component))]

def parse_queue_log(test_name):
    return parser.parse_queue_log(file('%s/log-queue-status.txt' % test_name))

def graph1_messages():
    graph_messages('full_test', 
                   time_range=(15 * 3600 + 50 * 60, 16 * 3600 + 40 * 60))

def graph1_memory():
    graph_memory('full_test',
                   time_range=(15 * 3600 + 50 * 60, 16 * 3600 + 40 * 60))

def graph2_messages():
    graph_messages('full_test_2', with_extra_router=False,
                   time_range=(16 * 3600 + 60 * 60, 17 * 3600 + 40 * 60))

def graph2_memory():
    graph_memory('full_test_2',
                 time_range=(16 * 3600 + 60 * 60, 17 * 3600 + 40 * 60))

def graph3_messages():
    graph_messages('full_test_3', with_consumers=True,
                   time_range=(17 * 3600 + 40 * 60, 19 * 3600))

def graph3_memory():
    graph_memory('full_test_3',
                 time_range=(17 * 3600 + 40 * 60, 19 * 3600))

def graph_messages(test_name, time_range=None, with_extra_router=True, with_consumers=False):
    logs_router = parse_logs(test_name, 'router')
    if with_extra_router:
        logs_router_extra = parse_logs(test_name, 'routerextra')
    logs_producers = parse_logs(test_name, 'productor')
    log_queue = parse_queue_log(test_name)
    if with_consumers:
        logs_consumers = parse_logs(test_name, 'consumidor')

    pyplot.subplot(212)
    pyplot.title('Total de mensajes producidos y ruteados')
    plotter.plot_producer_messages_sent(logs_producers, style='g--', 
                                        repeat_data_point_period=5,
                                        legend='M. producidos por c/instancia')

    plotter.plot_total_producer_messages_sent(logs_producers, style='g-', 
                                              repeat_data_point_period=5,
                                              legend='Total M. producidos')

    plotter.plot_consumer_messages_received(logs_router, style='r--', 
                                            legend='M. ruteados por c/instancia')
    if with_extra_router:
        plotter.plot_consumer_messages_received(logs_router_extra, style='r--')
        plotter.plot_total_consumer_messages_received(logs_router + 
                                                      logs_router_extra, 
                                                      style='r-',
                                                      legend='Total M. ruteados')
    else:        
        plotter.plot_total_consumer_messages_received(logs_router,
                                                      style='r-',
                                                      legend='Total M. ruteados')
    if with_consumers:
        plotter.plot_consumer_messages_received(logs_consumers, style='b--',
                                                legend='M. consumidos por c/instancia')
        plotter.plot_total_consumer_messages_received(logs_consumers, style='b-',
                                                      legend='Total M. consumidos')
    plotter.render_ticks(212)
    pyplot.legend(loc='upper left')
    pyplot.grid(True)
    if time_range:
        pyplot.xlim(*time_range)

    pyplot.subplot(211)
    pyplot.title('Mensajes encolados')
    plotter.plot_queue_messages(log_queue, styles=iter(['r-', 'g-', 'b-', 'y-']))
    plotter.render_ticks(211)
    pyplot.legend()
    pyplot.grid(True)
    if time_range:
        pyplot.xlim(*time_range)

def graph_memory(test_name, time_range=None):
    log_queue = parse_queue_log(test_name)
    
    pyplot.subplot(211)
    pyplot.title('Mensajes encolados')
    plotter.plot_queue_messages(log_queue, styles=iter(['r-', 'g-', 'b-', 'y-']))
    plotter.render_ticks(211)
    pyplot.legend()
    pyplot.grid(True)
    if time_range:
        pyplot.xlim(*time_range)

    pyplot.subplot(212)
    pyplot.title('Memoria utilizada por cola (KiBytes)')
    plotter.plot_queue_memory(log_queue, styles=iter(['r-', 'g-', 'b-', 'y-']))
    plotter.render_ticks(212)
    pyplot.legend()
    pyplot.grid(True)
    if time_range:
        pyplot.xlim(*time_range)

    
