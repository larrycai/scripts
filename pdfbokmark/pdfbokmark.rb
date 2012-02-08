#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$stderr.puts "start converting ..."
pdfHead = Hash.new
pdfBookmarks = Array.new
pkey=""
ptitle=""
plevel=""
STDIN.each {|line| 
  name,value = line.split(/: |\n/)
  if(name=="InfoKey")
    pkey = value
  elsif(name=="InfoValue")
    pvalue = value
    pdfHead[pkey] = pvalue
    #print pkey,pvalue,"\n"
  elsif(name=="BookmarkTitle")
    ptitle = value
  elsif(name=="BookmarkLevel")
    plevel = value
  elsif(name=="BookmarkPageNumber")
    pnumber= value
    pdfBookmarks += [[ptitle,plevel,pnumber]]
  else
    #puts name,value
  end
  #p Hash[*line.split(/: |\n/)]
  #print line
}
$stderr.puts "List pdf information"
#puts pdfHead
print "[ /Title (",pdfHead["Title"],")\n"
print "/Author (Author name)\n"
print "/Subject (Subject description)\n"
print "/Keywords (comma, separated, keywords)\n"
print "/ModDate (D:20061204092842)\n"
print "/CreationDate (",pdfHead["CreationDate"],")\n"
print "/Creator (",pdfHead["Creator"],")\n"
print "/Producer (",pdfHead["Producer"],")\n"
print "/DOCINFO pdfmark\n"

$stderr.puts "\nList bookmark information"
pdfBookmarks.each { |x| 
  #p x
  print "[/Title (",x[0],") /Page ",x[2]," /OUT pdfmark\n"
}
#[/Title (Prologue) /Page 1 /OUT pdfmark
