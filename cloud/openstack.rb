#!/usr/bin/env ruby

#http://blog.vuksan.com/2010/07/20/provision-to-cloud-in-5-minutes-using-fog/

require 'fog'
require 'optparse'
require 'fileutils'
require 'erb'
require 'yaml'

def main()
    options = {
        :provider => 'AWS',
        :aws_access_key_id => '5ddc3611-1000-4745-8b14-27baf9024d01:proj',
        :aws_secret_access_key => '6fb3d776-a040-43e8-a6c0-b47c87400766',
        :endpoint => "http://150.236.225.34:8773/services/Cloud",
        
        :command => "list",
        :instance_id => nil
    }

    option_parser = OptionParser.new do |opts|
    #    executable_name = File.basename($PROGRAM_NAME)
    #    opts.banner = "make ebooks from markdown plain text
    #    Usage: #{executable_name} [options]    
    #    "
        # Create a switch
        opts.on("-l","--list [INSTANCE_ID]","list all instance") do | instance_id |
            options[:command] = "list"
            options[:instance_id] = instance_id
        end
        opts.on("--start INSTANCE_ID","start instance") do |instance_id|
            options[:command] = "start"
            options[:instance_id] = instance_id
        end
        opts.on("--stop  INSTANCE_ID","stop instance") do |instance_id|
            options[:command] = "stop"
            options[:instance_id] = instance_id
        end          
        opts.on("-d","--debug","debug") do 
            options["debug"] = true
        end
        opts.on("-c","--create [IMAGE_ID]","create instance from image") do |image_id|
            options[:command] = "create"
            options[:image_id] = image_id
        end
        opts.on("-n","--name DISPLAY_NAME","give instance a name when creating") do |display_name|
            options[:display_name] = display_name
        end
        opts.on("-t","--terminate INSTANCE_ID","terminate/delete instance") do |instance_id|
            options[:command] = "terminate"
            options[:instance_id] = instance_id
        end
        opts.on("-r","--reboot INSTANCE_ID","reboot instance") do |instance_id|
            options[:command] = "reboot"
            options[:instance_id] = instance_id
        end        
  
    end

    option_parser.parse!
    puts options.inspect if options["debug"]

    compute = Fog::Compute.new({
            :provider => 'AWS',
            :aws_access_key_id => '5ddc3611-1000-4745-8b14-27baf9024d01:proj',
            :aws_secret_access_key => '6fb3d776-a040-43e8-a6c0-b47c87400766',
            :endpoint => "http://150.236.225.34:8773/services/Cloud"
    })

    puts compute if options["debug"]

    case options[:command] 
    when "list" then list(compute,options[:instance_id])
    when "start" then start(compute,options[:instance_id])
    when "stop" then stop(compute,options[:instance_id])
    when "create" then create(compute,options[:image_id],options[:display_name])
    when "terminate" then terminate(compute,options[:instance_id])
    when "reboot" then reboot(compute,options[:instance_id])
    
    else puts "\ncommand '#{options[:command]}' is not supported yet"
    end
    puts "\n\n..Thanks for using openstack.rb"
end

def list(connection,instance_id)
    instance_list = connection.servers.all
    num_instances = instance_list.length
    puts "We have " + num_instances.to_s()  + " servers"

    header = [:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:image_id ]
    if instance_id 
        display(connection.servers.get(instance_id),header)
    else
        instance_list.table(header)
    #connection.describe_instances('instance-id'=> 'i-0000000f')
    end           
    
    ###################################################################
    # Get a list of our images
    ###################################################################
    my_images_raw = connection.describe_images('Owner' => 'self')
    my_images = my_images_raw.body["imagesSet"]

    puts "\n###################################################################################"
    puts "Following images are available for deployment"
    puts "\nImage ID\tArch\t\tImage Location"

    #p my_images
    #  List image ID, architecture and location
    for key in 0...my_images.length
      print my_images[key]["imageId"], "\t" , my_images[key]["architecture"] , "\t\t" , my_images[key]["imageLocation"],  "\n";
    end    
end

def start(connection ,instance_id)
    server = connection.servers.get(instance_id)
    #server.start
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
    print "Now start server #{instance_id} ..."
    server.start
    # wait for it to be ready to do stuff
    server.wait_for { print "."; ready? }
    puts ""    
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
end

def stop(connection ,instance_id)
    server = connection.servers.get(instance_id)
    #server.start
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
    print "Now stop server #{instance_id} ..."
    server.stop
    # wait for it to be ready to do stuff
    server.wait_for { print "."; not ready? }
    puts ""
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
end

def create(connection,image_id,display_name,flavor_id="m1.tiny")
    image_id = "ami-00000001" unless image_id
    print "Now create server from image #{image_id} ..."
    server = connection.servers.create(:image_id=>image_id,:display_name=>display_name,:flavor_id =>flavor_id)
# wait for it to be ready to do stuff
    server.wait_for { print "."; ready? }
    puts ""    
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
    puts "Please use #{server.public_ip_address} to connect"
end

def terminate(connection ,instance_id)
    server = connection.servers.get(instance_id)
    #server.start
    #display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
    if server.state == "stopped"
        puts "Stopped instance can not be terminated, please start it first, this could be a bug (-^-)"
        return
    end
    print "Now terminate server #{instance_id} ..."
    server.destroy
    # wait for it to be ready to do stuff
    begin
      server.wait_for { print "."; false }
    rescue Fog::Errors::Error => exception
      if exception.message.include? "went away"
        puts ""
        server.state = "terminated"
        display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
      else
        puts "Failed to terminate, please check /var/log/nova/nova-api.log"
      end
    end
end
def reboot(connection ,instance_id)
    server = connection.servers.get(instance_id)
    #server.start
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
    
    print "Now rebooting server #{instance_id} ..."
    server.reboot
    # reboot will keep state running
    #p server.console_output
    #print "[stopped]"
    # wait for it to be ready to do stuff
    #server.wait_for { print "."; ready? }
    puts ""
    display(server,[:id, :display_name, :flavor_id, :public_ip_address, :private_ip_address, :state,:created_at,:image_id ])
end

#https://github.com/geemus/formatador/blob/master/lib/formatador/table.rb
def display(server,attributes=nil)
    #p server.attributes
    Formatador.display_table([server.attributes], attributes)
    #p server.instance_initiated_shutdown_behavior
    #p server.architecture
    #p server.volumes
end

main
