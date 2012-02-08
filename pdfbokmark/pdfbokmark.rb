#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

def getInput
    pdfHead = Hash.new
    pdfBookmarks = Array.new
    pkey=""
    title=""
    level=""
    
    $stderr.puts "start converting ..."
    STDIN.each {|line| 
        name,value = line.split(/: |\n/)
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
        puts "  /#{key} (#{value}))"
    end 
    puts "/DOCINFO pdfmark"
    
    # now comes to bookmark
    $stderr.puts "List bookmark information"
    bookmark.each { |title,level,number| 
      #p x
      puts "[/Title (#{title}) /Page #{number} /OUT pdfmark"
    }
    #[/Title (Prologue) /Page 1 /OUT pdfmark
end

pdfHead,pdfBookmarks = getInput()
writeInPdfmark(pdfHead,pdfBookmarks)