
def shard_ranges(num_nodes)
  # Returns the letter ranges for n nodes
  # n < 26
  max_nodes = 26
  if num_nodes >= max_nodes
    num_nodes = max_nodes
  end
  shard_size = (26/num_nodes).to_i
  ranges = []
  num_nodes.times do |i|
    start_i = (i*shard_size)
    end_i   = ((i+1)*shard_size)
    if i==num_nodes-1
      end_i = max_nodes-1
    end
    start_letter = (start_i + 'a'.ord).chr
    end_letter = (end_i + 'a'.ord).chr
    ranges.push [start_i, end_i]
  end
  return ranges
end

def get_node(ranges, s)
  s.downcase!
  c = s[0].ord - 'a'.ord
  ranges.each do |range|
    if c <= range[1]
      return range
    end
  end
  return ranges[-1]
end

ranges = shard_ranges(4)

p get_node(ranges, "1")