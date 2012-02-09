#!/usr/bin/env ruby
# encoding: UTF-8

#
# the count check solution is copied from W.Trevor King http://www.physics.drexel.edu/~wking/unfolding-disasters/posts/PDF_bookmarks_with_Ghostscript/pdf-merge.py

require 'optparse'

options = {}
option_parser = OptionParser.new do |opts|
    executable_name = File.basename($PROGRAM_NAME)
    opts.banner = "Convert raw metadata from pdftk to pdfmark format
    Usage: #{executable_name} [options]
    
    example: #{executable_name} -i <input> -o <pdfmarks>
    "
    # Create a switch
    opts.on("-o","--output",
        'output pdfmark file which can be used for gs, default is stdout') do |output_file|
        options[:output] = output_file
    end
    # Create a flag
    opts.on("-i","--input",
        'input is the raw data from pdftk command, default is stdin') do |input_file|
        options[:input] = input_file
    end
end

option_parser.parse!
#puts options.inspect


def getInput
    pdfHead = Hash.new
    pdfBookmarks = Array.new
    pkey=""
    title=""
    level=""
    
    $stderr.puts "Start converting ..."
    STDIN.each {|line| 
        #line = line.encode('utf-8')
        name,value = line.split(/: |\n/u) # /u means unicode
        case 
        when name=="InfoKey" then pkey = value
        when name=="InfoValue" then 
            pdfHead[pkey] = value
            #puts value
        when name=="BookmarkTitle" then title = value
        when name=="BookmarkLevel" then level = value
        when name=="BookmarkPageNumber" then 
            # this is page number
            pdfBookmarks += [[title,level,value]]
        else
            # $stderr.puts "Skipped: #{name}:#{value}"
        end
        #p Hash[*line.split(/: |\n/)]
        #print line
        #puts pdfHead
    }
    return pdfHead,pdfBookmarks

end

def writeInPdfmark(head,bookmark)
    # http://www.pdflib.com/fileadmin/pdflib/pdf/pdfmark_primer.pdf
    $stderr.puts "List pdf information"
    #puts head
    print "["
    head.each do |key,value|
        puts "  /#{key} (#{value})"
    end 
    puts "/DOCINFO pdfmark"
    
    # now comes to bookmark
    $stderr.puts "List bookmark information"
    bookmark.each_with_index { |bmk,i| 
        count = 0
        countString = ""
        title,level,number = bmk
        #print "index #{i},level #{level} \n"
        bookmark[i+1..bookmark.size].each {|t,newlevel,n|
            if newlevel == level
                break
            elsif newlevel.to_i == level.to_i + 1
                count += 1
            end            
        }
        countString = "/Count -#{count}" if count > 0
      #p x
        puts "[/Title (#{title}) #{countString} /Page #{number} /OUT pdfmark"
    }
    #[/Title (Prologue) /Page 1 /OUT pdfmark
end

pdfHead,pdfBookmarks = getInput()
writeInPdfmark(pdfHead,pdfBookmarks)