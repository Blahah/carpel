class Array

  def count_states
    states = {}
    self.each do |x|
      states[x] ||= 0
      states[x] += 1
    end
    states
  end

  def product
    self.inject(1, &:*)
  end

  def sum
    self.inject(0, &:+)
  end

end
