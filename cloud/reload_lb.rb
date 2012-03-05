#!/usr/bin/env ruby

require 'eventmachine'
require 'open-uri'
require 'erb'

URL = "http://192.168.4.1:9393/app"
CFG_FILE = "/etc/haproxy/haproxy.cfg"
TEMPLATE_CFG_FILE = CFG_FILE + ".erb"

EM.run do
  instances = []

  EventMachine::PeriodicTimer.new(5) do
    current_instances = open(URL).readline.split(",")
    unless instances == current_instances
      instances = current_instances

      cai = instances.map { |instance| "server #{instance} #{instance}:3300 check" }.join("\n\t")
      cai3g = instances.map { |instance| "server #{instance} #{instance}:8998 check" }.join("\n\t")

      template = ERB.new(File.read(TEMPLATE_CFG_FILE))
      File.write(CFG_FILE, template.result(binding))

      `/etc/init.d/haproxy reload`

      puts "haproxy reloaded"
    end
  end
end
