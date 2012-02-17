#!/usr/bin/env ruby
# encoding: UTF-8
#
# Copyright (C) 2011-2012 Larry Cai <larry.caiyu@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# Acknowledgement:
# the solution of counting check and unicode handling for pdf metadata
# is learned from W.Trevor King http://www.physics.drexel.edu/~wking/unfolding-disasters/posts/PDF_bookmarks_with_Ghostscript/

require 'optparse'

options = {}
option_parser = OptionParser.new do |opts|
    executable_name = File.basename($PROGRAM_NAME)
    opts.banner = "Convert raw metadata from pdftk to pdfmark format used in ghostscript
    Usage: #{executable_name} [options]    
    "
    # Create a switch
    opts.on("-o","--output FILE","input raw metadata from pdftk") do |output_file|
        options[:output] = output_file
    end
    # Create a flag
    opts.on("-i","--input FILE","output pdfmark for ghostscript") do |input_file|
        options[:input] = input_file
    end
end


def getInput(inputfile)
    pdfHead = Hash.new
    pdfBookmarks = Array.new
    pkey=""
    title=""
    level=""
    
    $stderr.puts "Start converting ..."
    inputfile.each {|line| 
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
            if title =~ /&#([0-9]+);/
                title.gsub!(/&#([0-9]+);/) do |num| 
                    abc = num[2..-2].to_i.to_s(16)
                    [abc.hex].pack("U")
                end
            else
                title = title
            end
            #puts title
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

def writeInPdfmark(outputfile,head,bookmark)
    # http://www.pdflib.com/fileadmin/pdflib/pdf/pdfmark_primer.pdf
    $stderr.puts "List pdf information"
    #puts head
    outputfile.print "["
    head.each do |key,value|
        outputfile.puts "  /#{key} (#{_pdfmark_unicode(value)})"
    end 
    outputfile.puts "/DOCINFO pdfmark"
    
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
        countString = "/Count -#{count} " if count > 0
        outputfile.puts "[ /Title #{_pdfmark_unicode(title)} /Page #{number} #{countString}/OUT pdfmark"
    }
    #[/Title (Prologue) /Page 1 /OUT pdfmark
end

# reuse pdf-merge.pl
# need consider for none unicode to (title) as before
def _pdfmark_unicode(string)
    bom_utf16_be = "\u{fe ff}"
    b= (bom_utf16_be + string).encode("UTF-16BE")
    output = ""
    # ugly for remove 00FE00FF -> FEFF
    index = 0
    b.each_byte do |byte|
        if index == 0 or index == 2
        else 
            output += "%02X" % byte
        end
        index +=1
    end
    return "<#{output}>"
end        

#print _pdfmark_unicode("\u{52 4d 8a 00}")
#exit

option_parser.parse!
# puts options.inspect

input  = options[:input]?  File.open(options[:input],"r:ASCII") : $<;
output = options[:output]? File.new(options[:output],"w:ASCII"): $>;
#input.set_encoding(Encoding::UTF-8)
    
pdfHead,pdfBookmarks = getInput(input)
writeInPdfmark(output,pdfHead,pdfBookmarks)