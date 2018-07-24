#!/usr/bin/ruby
# usage: ./iPerfGrapher.rb
# sample iperf command: "iperf -c <server> -i <interval> --reportstyle C -P <parallel>"
# this script requires the iperf option --reportstyle, to extract values from the CSV
# the -o or --output option in iperf does not seem to work in Mac OS
# TODO: is it possible to get losses?
# TODO: checkout iperf3, it can give output in JSON

require 'pp'
require 'gnuplot'
require 'csv'
require 'date'
require 'open3'


BEGIN {
  # this is called before the program is run
  puts "iPerfGrapher is starting...\n"
}

END {
  # this is called at the end of the program
  puts "\nPerfGrapher is ending..."
}


# when using --reportstyle C or -y C the data is in format:
# timestamp, srcAddr, srcPort, dstAddr, dstPort, transferID, interval, txBytes, bitsPerSecond
# https://serverfault.com/questions/566737/iperf-csv-output-format
# the very last row is the total
class IPerfData
	def initialize()
		@srcIP = ""
		@srcPort = ""
		@dstIP = ""
		@dstPort = ""
		@transferID = ""
		@sample = Array.new
		@timestamp = Array.new
		@interval = Array.new
		@txBytes = Array.new
		@bps = Array.new
	end

	attr_accessor :srcIP, :srcPort, :dstIP, :dstPort, :transferID, :sample, :timestamp, :interval, :txBytes, :bps

end


def plotData(h, fileLocation)
	# the input value is an Hash
	puts "Plotting throughput data..."
	unless h.instance_of?(Hash)
		puts "plotData was not given an Hash"
		return
	end


	Gnuplot.open do |gp|
		Gnuplot::Plot.new(gp) do |plot|
			# set general gnuplot things
			plot.terminal("png size 1280,720 transparent")
			plot.title("iPerf Throughput")
			plot.output(fileLocation)

			# stuff for x-axis
			plot.xlabel("Sample")
			plot.grid("xtics")
			plot.xrange("[0:]")

			# stuff for y-axis
			plot.ylabel("Throughput (Mbps)")
			plot.grid("ytics")
			plot.yrange("[0:]")

			plotGnuArray = Array.new(h.size) { |i|
				Gnuplot::DataSet.new([h[h.keys[i]].sample[0...-1], h[h.keys[i]].bps[0...-1]]) do |ds|
					ds.with = "lines"
					ds.title = "Flow ID: #{h.keys[i].to_s}"
					ds.linewidth = 4
				end
			}

			#puts plotGnuArray.class
			plot.data = plotGnuArray

		end
	end
end




iperfCommand = "iperf -c localhost -f M -i 1 -t 5 --reportstyle C -P 3"
outputDir = "/Users/davide/Desktop/Code/RUBY/iPerfGrapher/"
now = DateTime.now.strftime("%Y%b%d-%H%M%S")
puts "iperfCommand: #{iperfCommand}"
puts "outputDir: #{outputDir}"
puts "now: #{now}"

# run iperf, check if it connects successfully
stdout, stderr, status = Open3.capture3("#{iperfCommand}")
# puts stdout
# puts stderr
# puts status
if stderr.include?("connect failed")
	puts "iPerf failed to connect to the server."
	exit
end


# save raw data to file
rawFileLoc = outputDir + "rawdata_" + now + ".dat"
rawFile = File.open(rawFileLoc, "w")
rawFile << stdout
rawFile.close


# parse output of iPerf command
outputData = Hash.new

CSV.parse(stdout) do |row|
	# check if flow was already put in the hash using the transferID
	flowID = row[5]

	if outputData.has_key?(flowID)
		outputData[flowID].sample.push(outputData[flowID].sample.size.to_i)
		outputData[flowID].timestamp.push(row[0])
		outputData[flowID].srcIP = row[1]
		outputData[flowID].srcPort = row[2]
		outputData[flowID].dstIP = row[3]
		outputData[flowID].dstPort = row[4]
		outputData[flowID].transferID = row[5]
		outputData[flowID].interval.push(row[6])
		outputData[flowID].txBytes.push(row[7])
		outputData[flowID].bps.push(row[8].to_i / 1000000.0)	# convert in Mbps
	else
		outputData[flowID] = IPerfData.new
	end
end

# puts output
# puts "\n"
# puts outputData.sample
# puts "\n"
# puts outputData.sample[0...-1]
# puts "\n"
# puts outputData.size
# pp outputData

plotFileLoc = outputDir + "plot_" + now + ".png"
plotData(outputData, plotFileLoc)
