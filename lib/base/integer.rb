class Integer

  # binomial coefficient: n choose k
  def choose(k)
    # n!/(n-k)!
    top = (self-k+1 .. self).inject(1, &:*)
    # k!
    bottom = (2 .. k).inject(1, &:*)
    top / bottom
  end

end
