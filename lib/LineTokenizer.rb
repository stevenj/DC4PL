#  LineTokenizer.rb
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
require 'time'

# Tokenize the line read from a log into its component data
class LineTokenizer
    # Initialise the tokenised line object
    #
    # ==== Parameters
    #
    # * +line+  - the line read from the log file.
    def initialize(line)

        # convert a key to an integer
        #
        # ==== Parameters
        #
        # * +key+  - the key to convert.
        def key_to_int(key)
            # Dont do anything if key doesnt exist
            if @tokens.has_key?(key)
                # check if the value is an integer

                if ((@tokens[key] =~ /^\d+/) == 0) then
                    # Covnert the value of the key to an numeric value
                    @tokens[key] = @tokens[key].to_i
                else
                    # remove the key from the hash
                    @tokens.delete(key)
                end
            end
        end

        # Extract the contents of a Line for further easy processing.
        # Line Format is ISO_DATE_STRING ROUTER [key=value, ...]
        time, router, kvpairs = line.split(" ", 3)

        # Build the hash of line data from the kvpairs.
        @tokens = Hash[kvpairs.split.map {|kv| kv.split("=")}] rescue {}

        # Store the router info into the Hash
        @tokens["router"] = router

        # Store Date/Time (which is an ISO Date) into the Hash
        begin
            @tokens["time"] = DateTime.iso8601(time)
        rescue ArgumentError
            # If the Date/Time can not be processed we do not add a "time"
            # record to the fields.
        end

        # Convert tokens which should be numbers to integers
        key_to_int("connect")
        key_to_int("service")
        key_to_int("status")
        key_to_int("bytes")

        # validate and convert each field extracted to ensure its a well formed line.
        # Time is valid and all the Key/Value pairs we expect are present. Extra ones are ignored.

        # If not ALL the data is valid, then none of the data is valid.
        @tokens = {} if (["time", "router",
                          "at", "method", "path", "host", "fwd", "dyno",
                          "connect", "service", "status", "bytes"] - @tokens.keys).any?
    end


    # Return the tokenised data from the line
    #
    # ==== Parameters
    #
    # * +key+  - the key of the data to read.
    def [](key)
        @tokens[key]
    end
end

