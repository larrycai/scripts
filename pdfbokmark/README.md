### Introduction

http://unix.stackexchange.com/questions/17065/add-and-edit-bookmarks-to-pdf/31070#comment42048_31070
http://stackoverflow.com/questions/2969479/merge-pdfs-with-pdftk-with-bookmarks

http://www.pdflabs.com/docs/pdftk-cli-examples/
http://ubuntuforums.org/showthread.php?t=1545064
http://milan.kupcevic.net/ghostscript-ps-pdf/#marks
http://www.physics.drexel.edu/~wking/unfolding-disasters/posts/PDF_bookmarks_with_Ghostscript/
http://www.physics.drexel.edu/~wking/unfolding-disasters/posts/PDF_bookmarks_with_Ghostscript/pdf-merge.py

#### Usage

~~~~~~~~ {.bash}
pdftk input.pdf dump_data_utf8 > in.info
pdfbokmark.rb < in.info > pdfmarks # may update in.info before or pdfmarks
pdftk A=book-cover.pdf B=sdcamp.zh.pdf cat A3-4 B3-end A7 output merged.pdf
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=result.pdf merged.pdf pdfmarks
~~~~~~~~~~~~~~~~

#### PDFmarks

~~~~~~~~~~~~~~~~~~~~
## generated in.info
InfoKey: Creator
InfoValue: Cloud API Docs Plugin
InfoKey: Title
InfoValue: Cloud Files&#8482; Developer Guide
InfoKey: Producer
InfoValue: Apache FOP Version 1.0
InfoKey: CreationDate
InfoValue: D:20111115123218-06'00'
PdfID0: e941cffd7c16fbaba852f26754a562f8
PdfID1: e941cffd7c16fbaba852f26754a562f8
NumberOfPages: 51
BookmarkTitle: Cloud Files&#8482; Developer Guide
BookmarkLevel: 1
BookmarkPageNumber: 1
BookmarkTitle: Table of Contents
BookmarkLevel: 1
BookmarkPageNumber: 3
BookmarkTitle: 1. Overview
BookmarkLevel: 1
BookmarkPageNumber: 8
BookmarkTitle: 1.1.&#160;Intended Audience
BookmarkLevel: 2
BookmarkPageNumber: 8
BookmarkTitle: 1.2.&#160;Document Change History
BookmarkLevel: 2
BookmarkPageNumber: 9
~~~~~~~~~~~~~~~~~~~~

and the output should be something like below, see [pdfmark Reference Manual](http://partners.adobe.com/public/developer/en/acrobat/sdk/pdf/pdf_creation_apis_and_specs/pdfmarkReference.pdf) for more

~~~~~~~~~~~~~~~~
[ /Title (Document title)
  /Author (Author name)
  /Subject (Subject description)
  /Keywords (comma, separated, keywords)
  /ModDate (D:20061204092842)
  /CreationDate (D:20061204092842)
  /Creator (application name or creator note)
  /Producer (PDF producer name or note)
  /DOCINFO pdfmark
[/Title (Cloud Files&#8482; Developer Guide) /Page 1 /OUT pdfmark
[/Count 3 /Title (Chapter 1) /Page 1 /OUT pdfmark
[/Count -2 /Title (Section 1.1) /Page 2 /OUT pdfmark
[/Title (Section 1.1.1) /Page 3 /OUT pdfmark
[/Title (Section 1.2.2) /Page 3 /OUT pdfmark
[/Count -1 /Title (Section 1.2) /Page 4 /OUT pdfmark
[/Title (Section 1.2.1) /Page 4 /OUT pdfmark
[/Title (Section 1.3) /Page 3 /OUT pdfmark
~~~~~~~~~~~~~~~~~~~~~~