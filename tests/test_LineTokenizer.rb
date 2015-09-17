#  test_LineTokenizer.rb
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
require "./lib/LineTokenizer.rb"
require "test/unit"

require "time"

class TestLineTokenizer < Test::Unit::TestCase

  # Test the line tokenizer works as expected
  def test_tokenizer

    def all_nil(l)
        assert_equal(nil, l["time"])
        assert_equal(nil, l["router"])
        assert_equal(nil, l["at"])
        assert_equal(nil, l["method"])
        assert_equal(nil, l["path"])
        assert_equal(nil, l["host"])
        assert_equal(nil, l["fwd"])
        assert_equal(nil, l["dyno"])
        assert_equal(nil, l["connect"])
        assert_equal(nil, l["service"])
        assert_equal(nil, l["status"])
        assert_equal(nil, l["bytes"])
    end

    # Test valid line
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 connect=3ms service=15ms status=304 bytes=0')
    assert_equal(DateTime.new(2014, 1, 9, 6, 17, 14.925860, "+00:00"),l["time"])
    assert_equal("heroku[router]:", l["router"])
    assert_equal("info", l["at"])
    assert_equal("GET", l["method"])
    assert_equal("/api/users/100005722386120/count_pending_messages", l["path"])
    assert_equal("services.pocketplaylab.com", l["host"])
    assert_equal('"197.195.112.103"', l["fwd"])
    assert_equal("web.2", l["dyno"])
    assert_equal(3, l["connect"])
    assert_equal(15, l["service"])
    assert_equal(304, l["status"])
    assert_equal(0, l["bytes"])

    # Test Extra token (ignored)
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 feelings=good connect=3ms service=15ms status=304 bytes=0')
    assert_equal(DateTime.new(2014, 1, 9, 6, 17, 14.925860, "+00:00"),l["time"])
    assert_equal("heroku[router]:", l["router"])
    assert_equal("info", l["at"])
    assert_equal("GET", l["method"])
    assert_equal("/api/users/100005722386120/count_pending_messages", l["path"])
    assert_equal("services.pocketplaylab.com", l["host"])
    assert_equal('"197.195.112.103"', l["fwd"])
    assert_equal("web.2", l["dyno"])
    assert_equal(3, l["connect"])
    assert_equal(15, l["service"])
    assert_equal(304, l["status"])
    assert_equal(0, l["bytes"])

    # empty line
    l = LineTokenizer.new("")
    all_nil(l)

    # BAD TIME
    l = LineTokenizer.new('NOT-A-TIME heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 connect=3ms service=15ms status=304 bytes=0')
    all_nil(l)

    # BAD CONNECT
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 connect=Seventyms service=15ms status=304 bytes=0')
    all_nil(l)

    # BAD SERVICE
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 connect=3ms service=any_ms status=304 bytes=0')
    all_nil(l)

    # BAD STATUS
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 connect=3ms service=15ms status=GOOD bytes=0')
    all_nil(l)

    # BAD BYTES
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages host=services.pocketplaylab.com fwd="197.195.112.103" dyno=web.2 connect=3ms service=15ms status=304 bytes=eleven')
    all_nil(l)

    # MISSING HOST
    l = LineTokenizer.new('2014-01-09T06:17:14.925860+00:00 heroku[router]: at=info method=GET path=/api/users/100005722386120/count_pending_messages fwd="197.195.112.103" dyno=web.2 connect=3ms service=15ms status=304 bytes=0')
    all_nil(l)

  end

end
