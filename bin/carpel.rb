#! /usr/bin/env ruby

require 'carpel'
require 'trollop'

opts = Trollop::options do
  opt :sequence, "sequence to analyse", :type => :string
  opt :maxk, "maximum number of change-points", :default => 5
  opt :nullprior,
      "prior probability of having no change-points",
      :default => 0.5
  opt :alphabet,
      "full alphabet for the sequence",
      :type => :string,
      :default => 'actg'
end

s = Carpel::LiuSegmenter.new(opts.sequence.to_a,
                             opts.maxk,
                             opts.nullprior,
                             opts.alphabet.to_a)

n = (0..opts.maxk).map do |k|
  r = [k, s.prob_k_given_R(k)]
  puts "P(k=#{k}|R) = #{r[1]}"
  r
end.sort_by { |x| x[1] }.last[0]

puts "Most likely number of change-points: #{n}"
