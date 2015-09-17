#  test_Average.rb
#
#  Copyright 2015 Steven Johnson <sakurainds@gmail.com>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#
require "./lib/Average.rb"
require "test/unit"

require "time"

require 'benchmark'

def rand_range(x, y); rand(y+1 - x) + x; end

class TestAverage < Test::Unit::TestCase

  # Test the line tokenizer works as expected
  def test_average

    a = Average.new
    assert_equal(nil, a.mean)
    assert_equal(nil, a.mode)
    assert_raise_with_message(RuntimeError,
        'this method should be overriden and return the median of the data') do
        a.median
    end
    assert_equal(nil, a.range)

    assert_equal(1, a << 6)
    assert_equal(6, a.mean)
    assert_equal([6], a.mode)
    assert_raise_with_message(RuntimeError,
        'this method should be overriden and return the median of the data') do
        a.median
    end
    assert_equal(0, a.range)

    assert_equal(2, a << 9)
    assert_equal(7.5, a.mean)
    assert_equal([9,6], a.mode)
    assert_raise_with_message(RuntimeError,
        'this method should be overriden and return the median of the data') do
        a.median
    end
    assert_equal(3, a.range)

    assert_equal(3, a << 9)
    assert_equal(8, a.mean)
    assert_equal([9], a.mode)
    assert_raise_with_message(RuntimeError,
        'this method should be overriden and return the median of the data') do
        a.median
    end
    assert_equal(3, a.range)

    a1 = Average_LoMem.new
    assert_equal(nil, a1.mean)
    assert_equal(nil, a1.mode)
    assert_equal(nil, a1.median)
    assert_equal(nil, a1.range)

    a2 = Average_Fast.new
    assert_equal(nil, a2.mean)
    assert_equal(nil, a2.mode)
    assert_equal(nil, a2.median)
    assert_equal(nil, a2.range)

    assert_equal(1, a1 << 6)
    assert_equal(1, a2 << 6)
    assert_equal(2, a1 << 9)
    assert_equal(2, a2 << 9)
    assert_equal(3, a1 << 9)
    assert_equal(3, a2 << 9)

    assert_equal(8, a1.mean)
    assert_equal([9], a1.mode)
    assert_equal(9, a1.median)
    assert_equal(3, a1.range)

    assert_equal(8, a2.mean)
    assert_equal([9], a2.mode)
    assert_equal(9, a2.median)
    assert_equal(3, a2.range)


    # NOW a, a1 and a2 are all equal.
    # Add 1,000,000 random values to them equally.
    c, c1, c2 = 0
    1000000.times do |i|
        v = rand_range(5,10000)
        c = a << v
        c1 = a1 << v
        c2 = a2 << v
    end

    # Make sure they all continue to be equal.
    assert_equal(1000003, c)
    assert_equal(1000003, c1)
    assert_equal(1000003, c2)
    assert_equal(a.mean, a1.mean)
    assert_equal(a.mean, a2.mean)
    assert_equal(a.mode, a1.mode)
    assert_equal(a.mode, a2.mode)
    assert_equal(a.range, a1.range)
    assert_equal(a.range, a2.range)
    assert_equal(a1.median, a2.median)
  end

  def test_benchmark_average

    a1 = Average_LoMem.new
    a2 = Average_Fast.new

    puts

    Benchmark.bmbm do |x|
        x.report("Add 100,000 Value to LoMem") { 100000.times do a1 << rand_range(1000,20000) end }
        x.report("Add 100,000 Value to Fast")  { 100000.times do a2 << rand_range(1000,20000) end }
        x.report("Get Median LoMem") { 100.times do a1.median end }
        x.report("Get Median Fast")  { 100.times do a2.median end }
    end

    puts
  end

end
