module Carpel
require 'set'

class EmptySequenceError < StandardError; end

class LiuSegmenter

  attr_accessor :p_R_k, :p_R_ki, :p_R_k1rev

  # create a new LiuSegementer with a sequence
  # and optionally a maximum number of segments
  def initialize seq, maxk=10, null_prior=0.5, alphabet=nil
    if seq.length == 0
      raise EmptySequenceError.new "sequence must have length > 0"
    end
    @seq = seq.is_a?(String) ? seq.to_a : seq
    @maxk = maxk
    @null_prior = null_prior
    @alphabet = alphabet
    @mlR = nil
    @p_R_k = {};
    @p_R_ki = (0..@maxk).map{ |k| [] };
    @p_R_k1rev = [];
    load_states
  end

  # Find the set of all unique states in the sequence and store their
  # counts in the instance variable @states. If an alphabet is specified,
  # use it to pre-populate the states with zero-counts.
  def load_states
    @states = @alphabet ? Hash[@alphabet.map{ |x| [x, 0] }] : {}
    @seq.each do |s|
      @states[s] ||= 0
      @states[s] += 1
    end
  end

  # marginal likelihood of the sequence R
  # equation 1
  def marginal_likelihood_R
    return @mlR if @mlR
    @mlR = (0..@maxk).map do |k|
      prior_k(k) * prob_R_given_k(k)
    end.sum
  end

  # the prior probability of having k change-points
  # the null prior (i.e. that are are 0 change-points) is variable
  # and the priors for the rest of the distribution (k=1..@maxk)
  # are uniform with the remaining probability
  def prior_k k
    k == 0 ? @null_prior : ((1 - @null_prior) / @maxk)
  end

  # equation 17 for the case where k=0
  # probability of a sequence R given there are no changepoints
  def prob_R_given_zero_k
    return @p_R_k[0] if @p_R_k.key?(0)
    # when k=0 there is one segment and therefore only 1 way to organise
    # segment, i.e (n-1).choose(k) == 1.
    # This makes the left side of equation 17 equal to 1
    # so we are left with gamma(D) * (prod_d(gamma(n_k + 1))) / gamma(n_k + D)
    # where D is the number of states in the sequence, n_k is the length
    # of the sequence and d is the number of times each state occurs
    result = prob_R_given_k_rhs(@states, 0, @seq.length)
    @p_R_k[0] = result
    result
  end

  # probability of a sequence R given there is one changepoint
  def prob_R_given_unit_k
    return @p_R_k[1] if @p_R_k.key?(1)
    prob_R_given_zero_k
    # when k=1 there are two segments and therefore length.choose(1) ways to
    # organise the segments. We iterate through them all and store them so
    # they can be looked up by higher k.
    states = @states.clone
    total = @seq.length
    (0...@seq.length).each do |i|
      @p_R_ki[1][i] = []
      segstates = states.clone
      (@seq.length - 1).downto(i).each do |j|
        # get the probability of this segment given k=0
        segresult = prob_R_given_k_rhs(segstates, 0, j+1-i)
        # save it for lookup
        @p_R_ki[1][i][j] = segresult
        # decrease the count of the last base in this segment
        c = @seq[j]
        segstates[c] -= 1
      end
      # decrease the count of the first base in this sequence
      c = @seq[i]
      states[c] -= 1
    end
    matrix = @p_R_ki[1]
    # we have a flat prior on observing any given segmentation
    # to avoid zero priors, we have a lower limit of Float::MIN
    pA = [1 / (@seq.length-1).to_f, Float::MIN].max
    # now we can calculate the probability for k=1
    result = (0...matrix.length - 1).map do |i|
      # probability for the sequence to the left of the change point
      # i.e. from 0..i
      left = matrix[0][i]
      # probability for the sequence to the right of the change point
      # i.e. from i+1..n
      right = matrix[i+1][@seq.length-1]
      # probability for this segmentation
      r = left * right
      r * pA
    end.sum
    @p_R_k[1] = result
    result
  end

  # equation 17 excluding the (n-1).choose(k) part
  def prob_R_given_k_rhs states, k, length
    l = Math.gamma(states.keys.length)
    result = (0..k).map do
      upper = states.keys.map{ |d| Math.gamma(states[d] + 1) }.product
      lower = Math.gamma(length + states.keys.length)
      # probability for this segmentation
      l * (upper / lower)
    end.product
  end

  # probability of a sequence R given there are k changepoints
  # results for each possible segmentation and for the whole sequence
  # are cached
  # equation 18 from Liu & (1999)
  def prob_R_given_k k
    return prob_R_given_zero_k if k == 0
    return prob_R_given_unit_k if k == 1
    return @p_R_k[k] if @p_R_k.key?(k)
    # generate probabilities for all lower values of k
    prob_R_given_k k-1
    # now recursively lookup the components for this k
    lowerk = @p_R_ki[k-1]
    onek = @p_R_ki[1]
    onek.each{ |r| p r }
    # build the lookup matrix for all possible subsequences
    # by looking up values in the matrices built for lower
    # values of k
    (0...@seq.length - 1).each do |i|
      @p_R_ki[k][i] = []
      (@seq.length - 1).downto(i).each do |j|
        if i == j
          # segment is one element long, so lookup the directly
          # computed probability in the k=1 matrix
          segresult = onek[i][j]
        else
          # segment is at least 2 elements long, so split it
          # left hand side is looked up for k=k-1
          left = lowerk[0][i]
          # right side is looked up for k=1
          right = onek[i+1][j]
          # compute the probability for this segmentation
          segresult = left * right
          puts "i = #{i}, j = #{j}, seq = #{@seq[i..j]}, left = #{left}, right = #{right}, result = #{segresult}"
        end
        # save it for lookup
        @p_R_ki[k][i][j] = segresult
      end
    end
    # we have a flat prior on observing any given segmentation
    # to avoid zero priors as per Cromwell's rule, we have a
    # lower limit of Float::MIN
    pA = [1 / ((@seq.length-1).choose(k)).to_f, Float::MIN].max
    # now we can calculate the probability for k=k
    matrix = @p_R_ki[k]
    result = (0...matrix.length - 1).map do |i|
      # probability for the sequence to the left of the change point
      # i.e. from 0..i
      left = matrix[0][i]
      # probability for the sequence to the right of the change point
      # i.e. from i+1..n
      right = matrix[i+1][@seq.length-1]
      # probability for this segmentation
      r = left * right
      r * pA
    end.sum
    @p_R_k[k] = result
    result
  end

  # probability of the sequence R having k change-points betweens segments
  # given the sequence (by Bayes' rule)
  # equation 9
  def prob_k_given_R k
    pRk = prob_R_given_k k
    pk = prior_k k
    mlR = marginal_likelihood_R
    pkR = pRk * pk / mlR
    pkR
  end

  # finds the most likely number of changepoints present in the sequence
  # with an upper bound of @maxk - 1, returning an array [n_changepoints, prob]
  def n_changepoints
    (0..@maxk).map do |k|
      [k, self.prob_k_given_R(k)]
    end.sort_by { |x| x[1] }.last
  end

  # finds the most likely number of segments present in the sequence
  # with an upper bound of @maxk, returning an array [n_segments, prob].
  def n_segments
    res = n_changepoints
    res[0] += 1
    res
  end

end # BayesSegmenter

end # Carpel
