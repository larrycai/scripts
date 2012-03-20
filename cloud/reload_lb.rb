#!/usr/bin/env ruby

require 'eventmachine'
require 'open-uri'
require 'erb'
require 'daemons'

Daemons.daemonize

URL = "http://192.168.4.1:9393/app"
CFG_FILE = "/etc/haproxy/haproxy.cfg"
TEMPLATE_CFG_FILE = CFG_FILE + ".erb"

ENV["http_proxy"] = nil

EM.run do
  instances = []

  EventMachine::PeriodicTimer.new(5) do
    begin
      current_instances = open(URL).readline.split(",")
      unless instances == current_instances
        instances = current_instances

        cai = instances.map { |instance| "server #{instance} #{instance}:3300 check" }.join("\n\t")
        cai3g = instances.map { |instance| "server #{instance} #{instance}:8998 check" }.join("\n\t")

        template = ERB.new(File.read(TEMPLATE_CFG_FILE))
        File.open(CFG_FILE, "w") { |cfg_file| cfg_file.puts template.result(binding) }

        `/etc/init.d/haproxy reload`

        puts "haproxy reloaded"
      end
    rescue EOFError => ex
        STDERR.puts "IO error when fetching cluster info"
    end
  end
end
