#  Endpoint.rb
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

require_relative 'Average.rb'

# A Single Endpoint and its Average data
class Endpoint
    # The Endpoints method
    attr_reader :ep_method
    # The Endpoints path
    attr_reader :ep_path
    # The Textual ID of the endpoint
    attr_reader :ep_id
    # The number of times data is stored in the endpoint
    attr_reader :called
    # The name of the busiest dyno
    attr_reader :busiest_dyno
    # The collection of avaerages of the stored data
    attr_reader :averages

    # Class Method : Make a regex string from an endpoint, to wildcard {user_id}
    #
    # ==== Parameters
    #
    # * +ep_path+  - the endpoint path to convert to a regex.
    #
    # ==== Returns
    #
    # - The regex which will match the enpoint path.
    #
    def self.get_regexstring(ep_path)
        '^' + ep_path.sub( /{user_id}/i, "[0-9]+") + '$'
    end

    # Class Method : Make an ID string from method and endpoint
    #
    # ==== Parameters
    #
    # * +endpoint+    - An array defining the endpoint.
    # * +endpoint[0]+ - The Method of the endpoint. (string)
    # * +endpoint[1]+ - The Path of the endpoint. (string)
    #
    # ==== Returns
    #
    # - A String ID representing the Endpoint.
    #
    def self.make_endpoint_id(endpoint)
        endpoint[0]+ ':'+self.get_regexstring(endpoint[1])
    end

    # Initialise the Endpoint
    #
    # ==== Parameters
    #
    # * +endpoint+    - An array defining the endpoint.
    # * +endpoint[0]+ - The Method of the endpoint. (string)
    # * +endpoint[1]+ - The Path of the endpoint. (string)
    #
    def initialize(endpoint)
        @ep_method = endpoint[0]
        @ep_path   = endpoint[1]
        @ep_id     = self.class.make_endpoint_id(endpoint)
        # Create a Regex from the endpoint definition:
        @ep_regex = Regexp.new(self.class.get_regexstring(@ep_path),"i")

        @called = 0
        @averages = { :connect   => Average_LoMem.new,
                      :service   => Average_LoMem.new,
                      :responses => Average_LoMem.new,
                      :bytes     => Average_LoMem.new }
        @busiest_dyno = ""
        @longest_running_dyno = ""
        @dynos = Hash.new(0)
    end

    # Is this the same endpoint??
    #
    # ==== Parameters
    #
    # * +method+ - The Method of the endpoint. (string)
    # * +path+   - The Path of the endpoint. (string)
    #
    # ==== Returns
    #
    # - +true+ - The Method and Path match this endpoint.
    # - +false+ - The Method and Path DO NOT match this endpoint.
    #
    def is_endpoint?(method, path)
        @ep_method==method && (not @ep_regex.match(path).nil?)
        #self.class.make_endpoint_id(method,endpoint) == @endpoint_id
    end

    # Add data from a log to the endpoint information storage.
    #
    # ==== Parameters
    #
    # * +data+ - The Data to add from the endpoint, as tokenised by LineTokeizer.rb
    #
    # ==== Returns
    #
    # - The Number of times data has been added to the endpoint.
    #
    def add(data)
        if not self.is_endpoint?(data["method"],data["path"])
            raise "Cant add data, not the same endpoint."
        end
        @averages[:connect] << data["connect"]    # Accumulate connect times
        @averages[:service] << data["service"]    # Accumulate service times
        @averages[:responses] << data["connect"]+data["service"]
                                                  # Accumulate response times
        @averages[:bytes] << data["bytes"]        # Accumulate message sizes

        @dynos[data["dyno"]] += 1                 # Accumulate per dyno run count
        @busiest_dyno = data["dyno"] if @dynos[@busiest_dyno] < @dynos[data["dyno"]]
                                                  # Keep track of current "busiest" dyno.
        @called += 1    # Accumulate the number of times its called
    end
end

# A collection of endpoints
class Endpoints

    # Count of lines of data which dont match an Endpoint
    attr_reader :unprocessed_lines
    # Collection of endpoints
    attr_reader :endpoints

    # Initialise the Endpoint collection
    def initialize
        # The collection of known endpoints.
        @endpoints = {}
        # The number of data entries didnt match a known endpoint.
        @unprocessed_lines = 0
    end

    # Add an endpoint to the collection
    #
    # ==== Parameters
    #
    # * +endpoint+    - An array defining the endpoint.
    # * +endpoint[0]+ - The Method of the endpoint. (string)
    # * +endpoint[1]+ - The Path of the endpoint. (string)
    #
    # ==== Returns
    #
    # - The new Endpoint Object
    #
    def <<(endpoint)
        e_id = Endpoint.make_endpoint_id(endpoint)
        raise "Cant add the same endpoint twice" if @endpoints.has_key?(e_id)
        @endpoints[e_id] = Endpoint.new(endpoint)
    end

    # Returns the endpoint selected by a method and path
    #
    # ==== Parameters
    #
    # * +method+ - The Method of the endpoint. (string)
    # * +path+   - The Path of the endpoint. (string)
    #
    # ==== Returns
    #
    # - The Endpoint object selected by the Method and Path
    # - +nil+ - No Matching Endpoint Object.
    #
    def get_endpoint(method,path)
        @endpoints.each { | ep |
            return ep[1] if ep[1].is_endpoint?(method,path)
        }
        return nil
    end

    # Add data to the endpoint it belongs to.
    #
    # ==== Parameters
    #
    # * +data+ - The Data to add from the endpoint, as tokenised by LineTokeizer.rb
    #
    # ==== Returns
    #
    # - +true+  - The Endpoint exists and the Data was added to it.
    # - +false+ - The Endpoint does not exist.
    #
    def add(data)
        # Get the endpoint ID
        ep = self.get_endpoint(data["method"],data["path"])

        if ep.nil? then
            # Unknown Endpoint, so just count the number of lines we throw
            @unprocessed_lines += 1
            return false
        end

        ep.add(data)
        return true
    end

    # Allow is to iterate through the collected endpoint data
    #
    # ==== Parameters
    #
    # * +ep+ - The Next Endpoint object held in the collection.
    def each()
        # Iterate the endpoints, just returning the endpoint objects.
        @endpoints.each  { | ep | yield ep[1] }
    end
end
