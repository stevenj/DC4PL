#  test_PlayLabDC.rb
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
require "./lib/PlayLabDC.rb"
require "test/unit"

class TestPlayLibDC < Test::Unit::TestCase

  # Test the usage checker works for both a non existant and an existant file
  def test_usage
    # non existant file
    assert_equal(false, showUsage("ThisFileDoesNotExist", DEFAULT_LOG ))
    # existant file but read only
    assert_equal(false, showUsage("logs/sample_ro.log", DEFAULT_LOG ))
    # directory exists, but can not be read
    assert_equal(false, showUsage("logs", DEFAULT_LOG ))
    # existant file
    assert_equal(true, showUsage("logs/sample.log", DEFAULT_LOG ))
  end

end
