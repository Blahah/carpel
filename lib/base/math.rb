module Math

  def self.gamma x
    Math.exp(Math.lgamma(x)[0])
  end

end
