require 'helper'

class TestLiuSegmentations < Test::Unit::TestCase

  context "Generating segments" do

    should "work for n=2" do
      s = Carpel::Segmentations.new(2, 5)
      expected = [
        [[0,0], [1,4]],
        [[0,1], [2,4]],
        [[0,2], [3,4]],
        [[0,3], [4,4]]
      ]
      i = 0
      s.each do |seg|
        assert_equal expected[i], seg
        i += 1
      end
      assert_equal i, expected.length
    end

    should "work for n=3" do
      s = Carpel::Segmentations.new(3, 5)
      expected = [
        [[0,0], [1,1], [2,4]],
        [[0,0], [1,2], [3,4]],
        [[0,0], [1,3], [4,4]],
        [[0,1], [2,2], [3,4]],
        [[0,1], [2,3], [4,4]],
        [[0,2], [3,3], [4,4]]
      ]
      i = 0
      s.each do |seg|
        assert_equal expected[i], seg
        i += 1
      end
      assert_equal i, expected.length
    end

    should "work for n=4" do
      s = Carpel::Segmentations.new(4, 6)
      expected = 5.choose(3)
      i = 0
      s.each do |seg|
        i += 1
      end
      assert_equal expected, i
    end

  end

end
