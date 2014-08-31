require 'helper'

class TestLiuSegmenter < Test::Unit::TestCase

  context "Priors on k" do

    setup do
      seq = 'abcabcabc'.to_a
      @seg = Carpel::LiuSegmenter.new seq, 10
    end

    should "be 0.5 for k=1, i.e. a single segment" do
      assert_equal 0.5, @seg.prior_k(1)
    end

    should "be equal for all k > 1, i.e. more than one segment" do
      p = 0.5 / 9
      (2..10).each do |k|
        assert_equal p, @seg.prior_k(k), "k = #{k}"
      end
    end

  end

  context "Prebuilding the recursion" do

    setup do
      seq = 'aaaabbbbb'.to_a # length 9
      @seg = Carpel::LiuSegmenter.new seq, 10
    end

    should "set values for subsequences of unit k" do
      @seg.prob_R_given_unit_k
      # p @seg.p_R_k1rev
      # p @seg.p_R_ki[1]
      assert_equal 8, @seg.p_R_k1rev.length
      assert_equal 8, @seg.p_R_ki[1].length
    end

  end

  context "Calculating p(R|k)" do

    should "get P of sequence given single segment in simple cases" do
      # with a sequence of length one we have a single state,
      # and the probability of the sequence given a model with
      # a single segment should be 1
      seq = 'a'.to_a
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      assert_equal 1.0,
                   segmenter.prob_R_given_unit_k,
                   "length 1, single state"
      # # with a sequence of length four but a single state,
      # # the probability of the sequence given a model with
      # # a single segment should be 1
      # seq = 'aaaa'.to_a
      # segmenter = Carpel::LiuSegmenter.new(seq, 5)
      # assert_equal 1.0,
      #              segmenter.prob_R_given_unit_k,
      #              "length 4, single state"
      # with sequence of length two and two states,
      # the probability of the sequence given a model with
      # a single segment should be ((1/6))^5) = ~0.000128600
      seq = 'ab'.to_a
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      assert_in_delta 0.0001286,
                      segmenter.prob_R_given_unit_k,
                      0.0000001,
                      "length 2, two states"
      # with sequence of length 8 and two states,
      # the probability of the sequence given a model with
      # a single segment should be 1.007621098853471e-14
      seq = 'abababab'.to_a
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      assert_in_delta 1.007621098853471e-14,
                      segmenter.prob_R_given_unit_k,
                      0.0000001,
                      "length 8, two states"
    end

  end

  context "Estimating numbers of segments" do

    should "match published version" do
      seq = 'aaaaaaaaaabbbbbbbbbbbccccccccc'
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      expected = [
        5.31632006098326385e-05,
        0.0526287476085534501,
        0.821008586822634895,
        0.111656951100350288,
        0.0146525512678515345
      ]
      probs = (1..5).map{ |k| segmenter.prob_k_given_R(k) }
      assert_equal expected, probs
    end

    should "estimate 3 segments correctly" do
      seq = 'aaaaaaaaaabbbbbbbbbbbccccccccc'
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      assert_equal 3, segmenter.n_segments
    end

    should "estimate 2 segments correctly" do
      seq = 'aaaaaaaaaaaaaaabbbbbbbbbbbbbbb'
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      assert_equal 2, segmenter.n_segments
    end

    should "estimate 1 segment correctly" do
      seq = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      segmenter = Carpel::LiuSegmenter.new(seq, 5)
      assert_equal 1, segmenter.n_segments
    end

  end

end
