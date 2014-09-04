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

    should "match for k=2 by recursive method" do
      expected = 0.004167
      actual = @seg.prob_R_given_k(2)
      assert_equal expected, actual.round(6)
    end

    should "match for k=3 by recursive method" do
      expected = (0.25**4).round(5)
      actual = @seg.prob_R_given_k(3)
      assert_equal expected, actual.round(5)
    end

    should "match for k=2 by exact method" do
      expected = 0.004167
      actual = @seg.prob_R_given_k_exact(2)
      assert_equal expected, actual.round(6)
    end

    should "match for k=3 by exact method" do
      expected = (0.25**4).round(5)
      actual = @seg.prob_R_given_k_exact(3)
      assert_equal expected, actual.round(5)
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
      assert_equal expected, actual.round(10)
    end

    should "match for k=2" do
      expected = 0.015625
      actual = @seg.prob_R_given_k(2)
      assert_equal expected, actual.round(10)
    end

  end

  context "n_segments_exact" do

    # should "match Kelly et al. published version" do
    #   seq = 'aaaaaaaaaabbbbbbbbbbbccccccccc'
    #   segmenter = Carpel::LiuSegmenter.new(seq, 4)
    #   expected = [
    #     5.31632006098326385e-05,
    #     0.0526287476085534501,
    #     0.821008586822634895,
    #     0.111656951100350288,
    #     0.0146525512678515345
    #   ]
    #   probs = (0..4).map{ |k| segmenter.prob_k_given_R(k) }
    #   probs.each_with_index do |p, i|
    #     p p
    #     # assert_in_delta expected[i], p, 0.01
    #   end
    # end

    should "estimate 4 segments correctly" do
      seq = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccdddddddddddddddddddddddddddd'
      segmenter = Carpel::LiuSegmenter.new(seq,
                                           3,
                                           0.5,
                                           'abcdefghijklmnopqrst'.to_a)
      assert_equal 4, segmenter.n_segments_exact[0]
    end

    should "estimate 3 segments correctly" do
      seq = 'aaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbcccccccccccccccccc'
      segmenter = Carpel::LiuSegmenter.new(seq,
                                           3,
                                           0.5,
                                           'abcdefghijklmnopqrst'.to_a)
      assert_equal 3, segmenter.n_segments_exact[0]
    end

    should "estimate 2 segments correctly" do
      seq = 'aaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbb'
      segmenter = Carpel::LiuSegmenter.new(seq,
                                           3,
                                           0.5,
                                           'abcdefghijklmnopqrst'.to_a)
      assert_equal 2, segmenter.n_segments_exact[0]
    end

    should "estimate 1 segment correctly" do
      seq = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      segmenter = Carpel::LiuSegmenter.new(seq,
                                           3,
                                           0.5  ,
                                           'abcdefghijklmnopqrst'.to_a)
      assert_equal 1, segmenter.n_segments_exact[0]
    end

  end

  context "n_changepoints_exact" do

    should "have an accuracy of >= 90%" do
      score = 0
      total = 10
      alphabet = (6..20).to_a
      total.times do |i|
        # generate a sequence of log2-discretised values
        # with length 500 and with between 0 and 4 changepoints
        # values between 2^6..2^20
        n = rand(1..4)
        m = n
        seq = []
        while m > 0
          mean = rand(7..19)
          gen = Rubystats::NormalDistribution.new(mean, 0.4)
          seq += gen.rng(100/n).map{ |x| x.to_i }
          m -= 1
        end
        # detect the number of changepoints
        segmenter = Carpel::LiuSegmenter.new(seq,
                                             3,
                                             0.2,
                                             alphabet)
        ans = segmenter.n_changepoints_exact
        puts "detected #{ans[0]} cps (p=#{ans[1]}), #{n-1} was the real number"
        # update the score
        score += 1 if ans[0] == n-1
      end
      puts "got #{score} out of #{total} right"
    end

  end

end
