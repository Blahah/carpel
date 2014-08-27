require 'helper'

class TestBayesSegmenter < Test::Unit::TestCase

  context "BayesSegmenter" do

    should "match published version" do
      seq = 'aaaaaaaaaabbbbbbbbbbbccccccccc'
      segmenter = Carpel::BayesSegmenter.new(seq, 5)
      expected = [
        5.31632006098326385e-05,
        0.0526287476085534501,
        0.821008586822634895,
        0.111656951100350288,
        0.0146525512678515345
      ]
      (1..5).map do |k|
        assert_equal expected[k-1], segmenter.prob_k_given_R(k), "k=#{k}"
      end
    end

    should "estimate number of segments correctly" do
      seq = 'aaaaaaaaaabbbbbbbbbbbccccccccc'
      segmenter = Carpel::BayesSegmenter.new(seq, 5)
      assert_equal segmenter.n_segments, 3
    end

  end
end
