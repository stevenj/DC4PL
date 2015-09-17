#  test_Endpoint.rb
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

require './lib/Endpoint.rb'

class TestEndpoint < Test::Unit::TestCase
    def test_endpointClass

        # An Endpoint with no wildcard is not changed
        assert_equal("^No Changes$", Endpoint.get_regexstring("No Changes"))
        # An Endpoint with a wildcard is turned into a regext to match it
        assert_equal("^/api/users/[0-9]+/count_pending_messages$", Endpoint.get_regexstring("/api/users/{user_id}/count_pending_messages"))

        # Turn an Endpoint definition into an Endpoint ID
        assert_equal("GET:^/api/users/[0-9]+/get_friends_progress$", Endpoint.make_endpoint_id(["GET" ,"/api/users/{user_id}/get_friends_progress"]))

    end

    def test_endpointObject
        ep = Endpoint.new(["GET" ,"/api/users/{user_id}/get_messages"])

        # Check reset state
        assert_equal("GET", ep.ep_method)
        assert_equal("/api/users/{user_id}/get_messages", ep.ep_path)
        assert_equal("GET:^/api/users/[0-9]+/get_messages$", ep.ep_id)
        assert_equal(0, ep.called)
        assert_equal("", ep.busiest_dyno)
        assert_equal([:connect, :service, :responses, :bytes], ep.averages.keys)
        ep.averages.each { | av | assert_equal( 0, av[1].count ) }

        assert_equal(true, ep.is_endpoint?("GET" ,"/api/users/999999/get_messages"))
        assert_equal(false, ep.is_endpoint?("GET" ,"/api/users/999999/get_message"))

        assert_raise_with_message(RuntimeError,
            'Cant add data, not the same endpoint.') do
            ep.add({'method' => 'POST', 'path' => 'something/else'})
        end
    end
end
