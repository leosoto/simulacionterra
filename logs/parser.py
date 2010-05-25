import re

def time_to_seconds(time_string):
    h, m, s = (int(part) for part in time_string.split(':'))
    return h * 3600 + m * 60 + s

class LogItem(dict):
    def time_in_seconds(self):
        return time_to_seconds(self['Time'])

def parse_log(log_file):
    # Consume first 2 lines
    log_file.readline(); log_file.readline()
    return [LogItem(parse_log_item_line(line) for line in item_lines)
            for item_lines in log_items_lines(log_file)]

def parse_log_item_line(line):
    parts = line.split(': ', 1)
    if len(parts) == 1:
        return parts[0], "" # Corner case: Empty value
    else:
        return parts
    
def log_items_lines(log_file):
    current_item_lines = []
    for line in log_file:
        line = line.strip()
        if line == "":
            if current_item_lines:
                yield current_item_lines
                current_item_lines = []
        else:
            current_item_lines.append(line)
    if current_item_lines:
        yield current_item_lines

def parse_queue_log(queue_log_file):
    # Consume first line
    queue_log_file.readline()
    return [parse_queue_log_item_lines(item_lines)
            for item_lines in log_items_lines(queue_log_file)
            if len(item_lines) > 3] # Items with 3 lines have no data

def parse_queue_log_item_lines(lines):
    time = re.findall(r'\w+ \w+ \d+ (\d\d:\d\d:\d\d) \w+ \d+', lines[0])[0]
    lines_with_data = lines[2:-1]

    return LogItem({'Time': time, 
                    'queues': dict(parse_queue_log_data_line(l) 
                                   for l in lines_with_data)})

def parse_queue_log_data_line(data_line):
    name, messages, unack, unsent, memory = data_line.split("\t")
    memory_kbs = int(memory) / 1024
    return name, locals()
