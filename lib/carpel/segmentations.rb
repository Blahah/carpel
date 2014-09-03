module Carpel

class Segmentations

  def initialize n, length
    @n = n
    @length = length
  end

  def each &block
    generate_segments(@n, 0, @length, [], &block)
  end

  def generate_segments(n, start, stop, segments, &block)
    if n == 0
      # the previous segment was the final one
      # yield the segments
      block.call segments.clone
      return
    end
    (start...stop).each do |j|
      # create the segment from this start point to
      # this end-point. If this is the final segment,
      # the end-point is always the end of the sequence.
      segments[@n - n] = [start, (n == 1? @length-1 : j)]
      # Recursively generate any remaining segments.
      generate_segments(n-1, j+1, stop, segments, &block)
      # If this is the final segment, we stop iterating
      # so we don't repeat ourselves.
      break if n == 1
    end
  end

end # Segmentations

end # Carpel
