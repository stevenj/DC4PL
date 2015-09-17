#  Average.rb
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

# Store data and then report statistical summaries on the data when requested.
# Base Class, Use Average_LoMem or Average_Fast depending on your requirements.
class Average

    # Highest Value stored
    attr_reader :hi

    # Lowest Value stored
    attr_reader :lo

    # Count of data items stored
    attr_reader :count

    # Create an averaging data store
    def initialize
        @total = 0                # The total of all stored values
        @count = 0.0              # Count of all values stored
        @quantum = Hash.new(0)    # A count of each occurrence of each unique value.
        @hi = nil                 # Highest known value
        @lo = nil                 # Lowest known value
    end

    # Add a value to the averaged data
    #
    # ==== Parameters
    #
    # * +value+  - the value to add
    #
    # ==== Returns
    #
    # * the number of items added to be averaged
    def <<(value)
        # Keep track of highest and lowest values
        @hi = value if (@hi.nil? || value > @hi)
        @lo = value if (@lo.nil? || value < @lo)

        @total += value         # Accumulate all values.
        @quantum[value] += 1    # Increase the count of each occurence of a value
        @count += 1             # Increase count of all values stored
    end

    # Get the mean of values stored to-date
    #
    # ==== Returns
    #
    # * - the mean value of the data, or nil if no data
    def mean
        return nil if @count == 0
        @total/@count
    end

    # Return the mode of the values stored to-date
    #
    # ==== Returns
    #
    # * +mode+  - the mode value array or most prevalent values
    #           - nil if no data has been stored.
    #
    def mode
        return nil unless @count > 0
        mode=[]
        @quantum.sort_by { | val, cnt | cnt }.reverse_each {|val|
            if (mode.empty? || (@quantum[mode[-1]] == val[1]))
                mode << val[0]
            else
                break
            end
        }
        return mode
    end

    # Median is not defined in this class, choose an implementation below
    # Otherwise, this class can be used, just not this method.
    def median
        raise 'this method should be overriden and return the median of the data'
    end

    # Return the range of the stored items.
    #
    # ==== Returns
    #
    # * +range+ - the range of stored values.
    #           - nil if nothing stored
    #
    def range
        return nil unless @count > 0
        @hi-@lo
    end
end

# A low memory median using the mode hash storage
# Memory is reduced because we collate counts of occurences, so
# if an entry occurs multiple times it always consumes the same
# storage.  However, it is slower to find the median because
# we must traverse the list to find the mid point
#
# ====== NOTE
#
# This is ONLY low memory if there is significant redundancy in the
# data being analysed.  If the data is mostly unique then it is
# highly likely that the fast variant will consume less memory.
class Average_LoMem < Average


    # Create a memory efficient averaging data store
    def initialize
        # Call the parent initialisation
        super
        @values = nil           # The sorted list of all stored values
    end

    # Add a value to the averaged data
    #
    # ==== Parameters
    #
    # * +value+  - the value to add
    def <<(value)
        @values = nil  # Added a new value, so no longer sorted.
        # Call super last, so it can return what it needs to, consistently.
        super
    end

    # Get the median of values stored to-date
    #   This is the middle value of the ordered set of all values
    #
    # ==== Returns
    #
    # * - the median value of the data, or nil if no data
    def median
        return nil unless @count > 0

        # The Hi/Lo index for the median to get.
        midpoint_hi = (@count/2).floor
        midpoint_lo = ((@count-0.5)/2).floor
        mid_lo = nil
        mid_hi = nil

        # First element is 0, just like if its an array.
        total = -1

        # Cache the result of sorting the values for improved performance.
        # Approximately 10x faster than sorting every time.
        @values = @quantum.sort_by { | val, cnt | val } unless not @values.nil?

        # Sort the quantum of values, and scan through them
        @values.each { | val |
            # count up until we get to the median point
            total += val[1]
            # at the median point, capture the median values
            mid_lo = val[0] if mid_lo.nil? && total >= midpoint_lo
            mid_hi = val[0] if mid_hi.nil? && total >= midpoint_hi

            # Finish once we have both the median values
            break if not (mid_lo.nil? || mid_hi.nil?)
        }
        (mid_lo+mid_hi)/2.0
    end

end

# A Fast but less memory efficient median implementation
class Average_Fast < Average
    # Create a Fast averaging data store
    def initialize
        # Call the parent initialisation
        super
        @values = []            # The list of all stored values
        @values_sorted = false  # Indication if the values list is know to be sorted or not.
    end

    # Add a value to the averaged data
    #
    # ==== Parameters
    #
    # * +value+  - the value to add
    def <<(value)
        @values.push(value)     # Add the value to the list of all values
        @values_sorted = false  # Added a new value, so no longer sorted.
        # Call super last, so it can return what it needs to, consistently.
        super
    end

    # Get the median of values stored to-date
    #   This is the middle value of the ordered set of all values
    #
    # ==== Returns
    #
    # * - the median value of the data, or nil if no data
    # Approximately 5x faster than the Low Memory variant.
    def median
        return nil unless @count > 0

        # Sort the values if we arent sure if they are sorted or not.
        @values.sort! unless @values_sorted
        @values_sorted = true

        # If the set is even, we need the average of the two middle values
        # If we ignore that and always average the two middle values the
        # answer works for even and odd sets.
        (@values[@count/2] + @values[(@count-0.5)/2])/2.0
    end
end
