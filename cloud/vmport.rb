#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

PORT_MAP = {
  "220" => ["22", :ssh],
  "308" => ["3080", :http],
  "330" => ["3300", :cai],
  "198" => ["8998", :cai3g]
}

SILENT = "> /dev/null 2>&1"

def ps_command(ip, seq = "")
  "ps -ewwf | egrep 'ssh .*[0-9].*#{seq}:#{ip}:[0-9]+' | grep -v grep"
end

def start(ip, seq)
  command = "ssh"
  PORT_MAP.each_entry do |key, val|
    command += " -L#{key}#{seq}:#{ip}:#{val[0]}"
  end
  command += " -gfN localhost #{SILENT}"

  successful = system(command)
  yield successful, seq if block_given?
end

def stop(ip, seq)
  # hope we're killing the right people
  command = "#{ps_command(ip, seq)} | awk '{print $2}' | xargs kill -9 #{SILENT}"

  successful = system(command)
  yield successful if block_given?
end

def status(ip)
  ports = []
  `#{ps_command(ip)}`.split(" ").grep /-L(.*)/ do
    ports << $1.split(":")[0]
  end

  yield ports if block_given?
end

def execute_command(opts, options)
  options.seq ||= options.ip.split(".")[-1]
  case ARGV[0]
  when "start" then start(options.ip, options.seq) do |successful, seq|
      if successful
        PORT_MAP.each_entry do |key, val|
          puts "#{val[1].to_s}:#{" " * (10 - val[1].to_s.size)} #{key}#{seq}"
        end
      else
        puts "failed to start port forwarding"
      end
    end
  when "stop" then stop(options.ip, options.seq) do |successful|
      if successful
        puts "port forwarding stopped"
      else
        puts "failed to stop port forwarding"
      end
    end
  when "status" then status(options.ip) do |ports|
      ports.each do |p|
        entry = PORT_MAP.find { |e| p.include?(e[0]) }
        puts "#{entry[1][1].to_s}:#{" " * (10 - entry[1][1].to_s.size)} #{p}" if entry
      end
    end
  else puts opts
  end
end

def main
  options = OpenStruct.new

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} -i, --ip <ip> [-s, --seq <seq>] {start|stop|status}"

    opts.on("-i", "--ip ip", "ip address of the instance") do |ip|
      options.ip = ip
    end

    opts.on("-s", "--seq seq", "sequence number used as port suffix",
            "if omitted, last fragment of ip address will be used",
            "for status command, this option will be ignored") do |seq|
      options.seq = seq
    end

    opts.on_tail("-h", "--help", "show this message") do
      puts opts
      exit
    end
  end

  opts.parse!

  if not options.ip
    puts opts
  else
    execute_command(opts, options)
  end
end

main
