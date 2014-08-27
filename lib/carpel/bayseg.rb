module Carpel
require 'set'

class BayesSegmenter

  # create a new BayesSegementer with a sequence
  # and optionally a maximum number of segments
  def initialize seq, maxk=10
   @seq = seq
   @maxk = maxk
   @pRk_left_i = [[nil] * @seq.length] * @maxk
   @pR_unitk = {}
   @mlR = nil
   load_states
  end

  # Find the set of all unique states in the sequence and store them in
  # the instance variable @states
  def load_states
    @states = Set.new()
    @seq.each{ |c| @states.add(c) }
  end

  # marginal likelihood of the sequence R
  # equation 1
  def marginal_likelihood_R
    return @mlR if @mlR
    @mlR = (1..@maxk).reduce(0) do |sum, k|
      sum + prob_k(k) * prob_R_given_k(@seq, k)
    end
  end

  # prior probability the sequence is formed of k segments
  # equation 2
  def prob_k k
    1 / @maxk.to_f
  end

  # probability of observing the sequence R
  # given there is one segment
  # equation 6
  def prob_R_given_unit_k r
    # use cached value if possible
    return @pR_unitk[r] if @pR_unitk[r]
    # count the occurence of each state (theta_k,d)
    counts = r.count_states
    l = r.length.to_f # length of the kth segment (L_k)
    # intialise the dirichlet concentration parameter (alpha) for each state
    # as 1, and precalculate total alpha
    alpha = 1
    total_alpha = alpha * @states.size
    # populate the equation
    p1 = 1 # 1/(length choose 0) == 1
    p2l_lower = counts.keys.map{ |d| gamma(alpha) }.product
    p2l_upper = gamma(total_alpha)
    p2 = (0...r.length).each_with_index.map do |k, i|
      r_upper = counts.keys.map do |d|
        gamma(counts[d] + alpha)
      end.product
      r_lower = gamma(l + total_alpha)
      # remove the lost element from counts
      lost = r[i]
      counts[lost] -= 1
      l -= 1
      # return part two
      (p2l_upper / p2l_lower) *
      (r_upper / r_lower.to_f)
    end.product
    @pR_unitk[r] = p1 * p2
    @pR_unitk[r]
  end

  # probability of observing the sequence R
  # given there are k segments
  # equation 8 - 'dynamic recursion'
  def prob_R_given_k r, k
    return prob_R_given_unit_k(r) if k == 1
    (0...r.length).reduce(0) do |sum, i|
      # recurse for sequence to the left
      pRk = prob_R_given_k(r[0...i], k-1)
      # recurse for sequence to the right
      pRk1 = prob_R_given_unit_k(r[i...r.length])

      # puts "recursion p(R=R[0..#{i}]|k=#{k-1}) #{pRk}" +
          #  ", p(R=R[#{i+1}..L]|k=1) #{pRk1}"
      sum + pRk * pRk1
    end
  end

  # probability of the sequence R being made up of k distinct segments
  # given the sequence (by Bayes' rule)
  # equation 9
  def prob_k_given_R k
    pRk = prob_R_given_k(@seq, k)
    pk = prob_k(k)
    mlR = marginal_likelihood_R
    pkR = pRk * pk / mlR
    # puts "p(R|k=#{k}) = #{pRk}, p(K=#{k}) = #{pk}, p(R) = #{mlR}, so p(k=#{k}|R) = #{pkR}"
    puts "p(k=#{k}|R) = #{pkR}"
    pkR
  end

  def gamma x
    return Math.gamma(x)
    Math.exp(Math.lgamma(x)[0])
  end

  # finds the most likely number of segments present in the sequence
  # with an upper bound of @maxk, returning an array [n_segments, prob].
  def n_segments
    (1..@maxk).map do |k|
      [k, c.prob_k_given_R k]
    end.sort_by { |x| x[1] }.last
  end

end

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

end # BayesSegmenter

end # Carpel
