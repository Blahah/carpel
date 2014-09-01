require 'helper'

class TestLiuSegmenter < Test::Unit::TestCase

  context "Initializing a Segmenter" do

    should "reject an empty sequence" do
      assert_raise Carpel::EmptySequenceError do
        Carpel::LiuSegmenter.new []
      end
    end

  end

  context "Priors on k" do

    setup do
      seq = 'abcabcabc'.to_a
      @seg1 = Carpel::LiuSegmenter.new seq,
                                       3,
                                       0.5
      @seg2 = Carpel::LiuSegmenter.new seq,
                                       4,
                                       0.2
    end

    should "be as specified for the null case" do
      assert_equal 0.5, @seg1.prior_k(0)
      assert_equal 0.2, @seg2.prior_k(0)
    end

    should "be uniformly spead across other cases" do
      p1 = (1 - 0.5) / 3
      (1..3).each do |k|
        assert_equal p1, @seg1.prior_k(k)
      end
      p2 = (1 - 0.2) / 4
      (1..4).each do |k|
        assert_equal p2, @seg2.prior_k(k)
      end
    end

  end

  context "Borodovsky & Ekisheva (2006) worked examples" do

    setup do
      seq = 'ggca'.to_a
      @seg = Carpel::LiuSegmenter.new seq,
                                      3,
                                      0.25,
                                      'acgt'.to_a
    end

    should "match for k=0" do
      expected = 1/420.0
      assert_in_delta expected, @seg.prob_R_given_zero_k, 0.001
    end

    should "match for k=1" do
      expected = 0.0009
      actual = @seg.prob_R_given_unit_k * 0.25
      assert_equal expected, actual.round(4)
    end

    should "match for k=2" do
      expected = 0.001
      actual = @seg.prob_R_given_k(2) * 0.25
      assert_equal expected, actual.round(3)
    end

    should "match for k=3" do
      expected = (0.25**4).round(4)
      actual = @seg.prob_R_given_k(3)
      assert_equal expected, actual.round(4)
    end

  end

  context "Manually worked examples with DNA seq 'ACT'" do

    setup do
      seq = 'act'.to_a
      @seg = Carpel::LiuSegmenter.new seq,
                                      2,
                                      (1/3.0),
                                      'acgt'.to_a
    end

    should "match for k=0" do
      expected = (1 / 720.0) * 6
      actual = @seg.prob_R_given_k(0)
      assert_equal expected, actual
    end

    should "match for k=1" do
      expected = 0.0125
      actual = @seg.prob_R_given_k(1)
      assert_equal expected, actual
    end

    should "match for k=2" do
      expected = 0.015625
      actual = @seg.prob_R_given_k(2)
      assert_equal expected, actual
    end

  end

  # context "n_segments" do
  #
  #   should "match Kelly et al. published version" do
  #     seq = 'aaaaaaaaaabbbbbbbbbbbccccccccc'
  #     segmenter = Carpel::LiuSegmenter.new(seq, 5)
  #     expected = [
  #       5.31632006098326385e-05,
  #       0.0526287476085534501,
  #       0.821008586822634895,
  #       0.111656951100350288,
  #       0.0146525512678515345
  #     ]
  #     probs = (1..5).map{ |k| segmenter.prob_k_given_R(k) }
  #     probs.each_with_index do |p, i|
  #       assert_in_delta expected[i], p, 0.01
  #     end
  #   end
  #
  #   should "estimate 3 segments correctly" do
  #     seq = 'aaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbcccccccccccccccccc'
  #     segmenter = Carpel::LiuSegmenter.new(seq,
  #                                          5,
  #                                          0.2,
  #                                          'abcdefghijklmnopqrst'.to_a)
  #     assert_equal 3, segmenter.n_segments[0]
  #   end
  #
  #   should "estimate 2 segments correctly" do
  #     seq = 'aaaaaaaaaaaaaaabbbbbbbbbbbbbbb'
  #     segmenter = Carpel::LiuSegmenter.new(seq,
  #                                          5,
  #                                          0.2,
  #                                          'abcdefghijklmnopqrst'.to_a)
  #     assert_equal 2, segmenter.n_segments[0]
  #   end
  #
  #   should "estimate 1 segment correctly" do
  #     seq = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  #     segmenter = Carpel::LiuSegmenter.new(seq,
  #                                          5,
  #                                          0.2,
  #                                          'abcdefghijklmnopqrst'.to_a)
  #     assert_equal 1, segmenter.n_segments[0]
  #   end
  #
  # end

end
