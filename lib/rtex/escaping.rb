require 'rexml/document'
require 'rubygems'
require 'xml/xslt'
require 'tidy'

module RTeX
  
  module Escaping

    BS        = "\\\\"
    BACKSLASH = "#{BS}textbackslash{}"
    HAT       = "#{BS}textasciicircum{}"
    TILDE     = "#{BS}textasciitilde{}"
    Tidy.path = '/usr/lib/libtidy.so'

   def escape(s)
   #tidy up the input html
   Tidy.open do |tidy|
     tidy.options.show_body_only = true
     tidy.options.output_xhtml = true
     tidy.options.wrap = 0
     tidy.options.char_encoding = 'utf8'
     tidy.options.quote_nbsp = false
     tidy.options.bare = true
     tidy.options.ncr = false
     tidy.options.mergedivs = true
     s=tidy.clean(s)
   end
   # wrapping html fragment into xml document
   s = s.gsub(/\\/, '\\textbackslash').gsub(/\&\s/,'&amp; ')
   part=s.gsub(/([{}])/, "#{BS}\\1")
   xmlstring = '<?xml version="1.0" encoding="utf-8" ?><dummy>'+part+'</dummy>'
   doc=REXML::Document.new(xmlstring)
   #definfing xslt tranformation
   xslstring=%{ 
	<?xml version="1.0" encoding="utf-8"?>
	<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			version="1.0">
	  <xsl:output encoding="UTF-8" indent="no" method="text" omit-xml-declaration="yes" />
	  <xsl:template match="/">
		<xsl:apply-templates/>
	  </xsl:template>

	  <xsl:template match="dummy">
		<xsl:apply-templates/>
	  </xsl:template>

	  <xsl:template match="dummy/*[position()=1][child::li]">
	  \\begin{list}{\\bullet}{\\setlength{\\topsep}{0pt}\\setlength{\\leftmargin}{\\labelsep + 8pt}\\setlength{\\parskip}{0pt}\\setlength{\\partopsep}{0pt}}<xsl:apply-templates/>\\end{list}
	  </xsl:template>

	  <xsl:template match="ul">\\begin{itemize}<xsl:apply-templates/>\\end{itemize}</xsl:template>
	  <xsl:template match="ul[li[@class]]">
	    \\begin{description}<xsl:apply-templates/>\\end{description}
	  </xsl:template>

	  <xsl:template match="ol">\\begin{enumerate}<xsl:apply-templates/>\\end{enumerate}</xsl:template>
	  <xsl:template match="li">\\item <xsl:apply-templates /></xsl:template>
	  <xsl:template match="li[@class='pos']">
	    \\item[$+$] <xsl:apply-templates />
	  </xsl:template>

	  <xsl:template match="li[@class='neg']">
	    \\item[$-$] <xsl:apply-templates />
	  </xsl:template>

	  <xsl:template match="dl">
	    \\begin{description}<xsl:apply-templates select="dt"/>\\end{description}
	  </xsl:template>

	  <xsl:template match="dt">
	    \\item[<xsl:value-of select="."/>] <xsl:apply-templates select="following-sibling::dd[1]"/>
	  </xsl:template>

	  <xsl:template match="dd[ul]">
	\\hfill{} 
	<xsl:apply-templates select="ul" />  
	  </xsl:template>
	  <xsl:template match="dd">
	       <xsl:apply-templates  />  
	  </xsl:template>
	  <xsl:template match="p[child::text()=' ']"></xsl:template>
	  <xsl:template match="p"><xsl:apply-templates  /><xsl:text disable-output-escaping="yes">

	  </xsl:text></xsl:template>
	  <xsl:template match="i">\\textit{<xsl:apply-templates  />}</xsl:template>
	  <xsl:template match="b">\\textbf{<xsl:apply-templates  />}</xsl:template>
	  <xsl:template match="em">\\textit{<xsl:apply-templates  />}</xsl:template>
	  <xsl:template match="strong">\\textbf{<xsl:apply-templates  />}</xsl:template>
	  <xsl:template match="a[@href]"><xsl:apply-templates  /> (<xsl:value-of select="href"/>)</xsl:template>
	  <xsl:template match="span"><xsl:apply-templates  /></xsl:template>
	  <xsl:template match="div"><xsl:apply-templates  /></xsl:template>
	</xsl:stylesheet>
	}

    xsl=REXML::Document.new(xslstring)
    xslt = XML::XSLT.new()
    xslt.xml = doc
    
    xslt.xsl = xsl
    out = xslt.serve()
 
    #doing some final substitutions	
    s=out.gsub(/([_$])/, "#{BS}\\1").
    gsub(/</, '$<$').
    gsub(/>/, '$>$').
    gsub(/"/, '"{}').
    gsub(/\&Auml;/, '"A').
    gsub(/\&Ouml;/, '"O').
    gsub(/\&Uuml;/, '"U').
    gsub(/\&auml;/, '"a').
    gsub(/\&ouml;/, '"o').
    gsub(/\&uuml;/, '"u').
    gsub(/\&szml;/, '"s').
    gsub(Regexp.quote('&amp;'), Regexp.quote('&')).
    gsub(/([&%#])/, "#{BS}\\1").
    gsub(/\^/, HAT).
    gsub(/~/, TILDE)
  end
 end
  
end
