#!/usr/bin/env ruby
#  PlayLabDC.rb
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

require_relative "LineTokenizer.rb"
require_relative "Endpoint.rb"

# Default log file name if none given on command line
DEFAULT_LOG = 'logs/sample.log'

# Definition of Endpoints to be processed from the log
ENDPOINTS = [
    ["GET" ,"/api/users/{user_id}/count_pending_messages"],
    ["GET" ,"/api/users/{user_id}/get_messages"],
    ["GET" ,"/api/users/{user_id}/get_friends_progress"],
    ["GET" ,"/api/users/{user_id}/get_friends_score"],
    ["POST","/api/users/{user_id}"],
    ["GET" ,"/api/users/{user_id}"]
]

# Formatting for the title rows in the output
TITLE_ROW = "%-4s : %-45s : %-8s : %-8s%s%-8s%s%-8s%s%-8s : %-8s : %-8s : %-8s\n"
# Formatting for the data rows in the output
DATA_ROW  = "%-4s : %-45s : %8d : %8.2f : %8d : %8s : %8d : %-8s : %8.2f : %8d\n"


# Reads a log, optionally named on the command line, Extracts information from the log
# and then Reports statistical data from that information.
class PlayLabDC

    # Initialise the log processing class
    #
    # ==== Parameters
    #
    # * +logfile+  - the log file name to be read.
    #
    def initialize(logfile)

        # remeber the name of the log to process.
        @logfile = logfile
        @endpoints = Endpoints.new
        @loglines = 0

        # Add all interesting Endpoints to be recorded
        ENDPOINTS.each do | ep | @endpoints << ep end
    end

    # Process the log file, line at a time.
    def process_logfile
        # Read each line from the logfile and process it.
        IO.foreach(@logfile) { |line|
            @endpoints.add(LineTokenizer.new(line))
            @loglines += 1
        }
    end

    # Display the results of the Processed log file.
    def display_results

        title1 = sprintf(TITLE_ROW, "METH", "PATH", "CALLED", "RESPONSE TIME(ms)","", "", "", "","","", "DYNO", "MESSAGE", "SIZE")
        puts(title1)
        printf(TITLE_ROW, "", "", "Times", "Mean"," : ","Median"," : ","Mode"," : ", "Range", "Busiest", "Average", "Max")
        puts('-'*title1.length)
        @endpoints.each do | ep |
            if ep.called == 0 then
                printf(TITLE_ROW, ep.ep_method,ep.ep_path, "   Never", " "," : "," "," : "," "," : ", " ", " ", " ", " ")
            else
                printf(DATA_ROW,
                        ep.ep_method,
                        ep.ep_path,
                        ep.called,
                        ep.averages[:responses].mean,
                        ep.averages[:responses].median,
                        ep.averages[:responses].mode,
                        ep.averages[:responses].range,
                        ep.busiest_dyno,
                        ep.averages[:bytes].mean,
                        ep.averages[:bytes].hi)
            end
        end

        if @endpoints.unprocessed_lines > 0
            puts "There were #{@endpoints.unprocessed_lines} Unprocessed Lines of data from #{@loglines} total lines in the log!"
        else
            puts "All #{@loglines} total lines in the log were processed!"
        end
    end

end

# Shows the titles, checks the paramters and prints usage if required.
#
# ==== Parameters
#
# * +filename+  - the file name to be read.
# * +defaultfn+ - The default filename if none given on the command line.
#
# ==== Returns
#
# * +true+  - Headings are printed and file can be read.
# * +false+ - Headings and usage are printed and the file can NOT be read.
#
def  showUsage(filename, defaultfn)
    # Emit the Programs Title.
    puts "Developer Challenge from PlayLab"
    puts "--------------------------------"
    puts

    # Check if the logfile exists and is readable
    readable = (File.file?(filename) and File.readable?(filename))

    # If the file can not be read then show some usage.
    if not readable
        puts "Usage:"
        puts "#{$PROGRAM_NAME} <filename>"
        puts "<filename> is the name of a log file to process, defaults to #{defaultfn}"
        puts ""
        ftype = File.exists?(filename) ? File.ftype(filename) : "Non Existant"
        puts "Error: #{filename} is #{ftype} and is unable to be read.  It can not be processed."
    end

    return readable
end

# Main entry point of the program
#
# ==== Parameters
#
# * +ARGV+  - (Optional) the file name to be read.
#
def main
    # Default argument to the log file if none specified
    ARGV << DEFAULT_LOG if ARGV.empty?

    # Get the name of the logfile to process
    logfile = ARGV[0]

    # show titles and usage if parameter is incorrect
    if showUsage(logfile, DEFAULT_LOG)
        # Initialise the Log Processor
        dc = PlayLabDC.new(logfile)

        # Process the logfile
        dc.process_logfile

        # Display the results of processing
        dc.display_results
    end
end

# Script Execution as command
if __FILE__ == $0
    # Call the main entry point, if we are executed from the command line
    main
end
