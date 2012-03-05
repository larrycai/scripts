#!/usr/bin/env ruby

require 'eventmachine'
require 'open-uri'

URL = "http://192.168.4.1:9393/app"
CFG_FILE = "/etc/haproxy/haproxy.cfg"
TEMPLATE_CFG_FILE = CFG_FILE + ".template"

EM.run do
  instances = []

  EventMachine::PeriodicTimer.new(1) do
    current_instances = open(URL).readline.split(",")
    unless instances == current_instances
      instances = current_instances
      File.open(TEMPLATE_CFG_FILE, "r") do |template_cfg_file|
        content = template_cfg_file.readlines.join("")
        sub_cai_content = instances.map { |instance| "server #{instance} #{instance}:3300 check" }.join("\n\t")
        sub_cai3g_content = instances.map { |instance| "server #{instance} #{instance}:8998 check" }.join("\n\t")
        content.gsub!("\${cai}", sub_cai_content)
        content.gsub!("\${cai3g}", sub_cai3g_content)

        File.open(CFG_FILE, "w") { |cfg_file| cfg_file.puts content }
      end

      `/etc/init.d/haproxy reload`

      puts "haproxy reloaded"
    end
  end
end
