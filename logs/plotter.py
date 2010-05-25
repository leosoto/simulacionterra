import matplotlib.pyplot as pyplot
from matplotlib.ticker import FuncFormatter, MultipleLocator
from itertools import cycle
from parser import LogItem

STYLES = cycle(['%s%s' % (color, line_style)
                for line_style in ('-', '--', '-.')
                for color in ('r', 'g', 'b', 'c', 'm', 'y')])

def set_axis_limits(consumer_logs):
    start_time = min(*(consumer_log[0].time_in_seconds()
                       for consumer_log in consumer_logs))
    end_time = max(*(consumer_log[-1].time_in_seconds()
                     for consumer_log in consumer_logs))
    pyplot.xlim(start_time, end_time)    

def render_ticks(subplot_num):
    x = pyplot.subplot(subplot_num).xaxis
    x.set_major_formatter(FuncFormatter(seconds_to_time_without_seconds))
    x.set_major_locator(MultipleLocator(60 * 5))
    x.set_minor_locator(MultipleLocator(60))

def plot_consumer_messages_received(consumer_logs, **kwargs):
    plot_time_series(consumer_logs, 'Total messages received', **kwargs)

def plot_total_consumer_messages_received(consumer_logs, **kwargs):
    plot_total_time_series(consumer_logs, 'Total messages received', **kwargs)

def plot_total_producer_messages_sent(producer_logs, **kwargs):
    plot_total_time_series(producer_logs, 'Total messages sent', **kwargs)

def plot_producer_messages_sent(producer_logs, **kwargs):
    plot_time_series(producer_logs, 'Total messages sent', **kwargs)

def plot_queue_messages(queue_log, **kwargs):
    plot_queue_data(queue_log, 'messages', **kwargs)

def plot_queue_memory(queue_log, **kwargs):
    plot_queue_data(queue_log, 'memory_kbs', **kwargs)

def plot_queue_data(queue_log, data_field, **kwargs):
    queues = queue_log[-1]['queues'].keys()
    for q in queues:
        plot_time_series([queue_log], 
                         rescue_with_0(lambda i: i['queues'][q][data_field]),
                         legend=q, **kwargs)

def rescue_with_0(l, *args):
    def new_l(*args):
        try:
            return l(*args)
        except:
            return 0
    return new_l

def plot_time_series(logs, field, style=None, styles=None, legend='_nolegend_', **kwargs):
    for log_items in logs:
        x_values, y_values = time_series(log_items, field, **kwargs)
        line, = pyplot.plot(x_values, y_values, style or (styles or STYLES).next())
    # Intentionally only put the legend in one line
    line.set_label(legend)

def plot_total_time_series(logs, field, style=None, styles=None, legend='_nolegend_', **kwargs):
    log_items = total_over_time(logs, field)
    x_values, y_values = time_series(log_items, field, **kwargs)
    pyplot.plot(x_values, y_values, style or (styles or STYLES).next(), label=legend)


def total_over_time(logs, field):
    totalized_log_items = []
    log_iters = [iter(l) for l in logs]
    next_items = [log_iter.next() for log_iter in log_iters]
    last_items = [LogItem({field: 0})] * len(logs)
    while any(item is not None for item in next_items):
        min_i = None
        min_item = None
        for i, item in enumerate(next_items):
            if item is not None:
                if (min_item is None) or (item.time_in_seconds() < min_item.time_in_seconds()):
                    min_i = i
                    min_item = item
        last_items[min_i] = min_item
        try:
            next_items[min_i] = log_iters[min_i].next()
        except StopIteration:
            next_items[min_i] = None

        totalized_log_items.append(
            LogItem({'Time': min_item['Time'],
                     field: sum(int(item[field]) for item in last_items)}))
    return totalized_log_items

def time_series(log_items, field, repeat_data_point_period=None):
    if not callable(field):
        field_name = field
        field = lambda i: i[field_name]
    data = []
    last_time, last_value = None, None
    for item in log_items:
        time, value = item.time_in_seconds(), field(item)
        if last_value and repeat_data_point_period:
            repeat_time = last_time + repeat_data_point_period
            while repeat_time < time:
                data.append((repeat_time, last_value))
                repeat_time += repeat_data_point_period
        data.append((time, value))
        last_time, last_value = time, value
    return zip(*data)

def seconds_to_time_without_seconds(seconds, pos=None):    
    hours, remainder = seconds / 3600, seconds % 3600
    minutes, seconds = remainder / 60, remainder % 60
    return '%02d:%02d' % (hours, minutes)

