<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="2.0" 
  xmlns:msg="http://www.SDMX.org/resources/SDMXML/schemas/v2_0/message"
  xmlns:ons="http://www.ons.gov.uk/schemas"
  xmlns:structure="http://www.SDMX.org/resources/SDMXML/schemas/v2_0/structure"
  xmlns:wdp="urn:sdmx:org.sdmx.infomodel.keyfamily.KeyFamily=ONS:PPI_CSDB_DS:1.0:cross">

  <xsl:output method="text" omit-xml-declaration="yes"/>
  <xsl:strip-space elements="*"/>

  <xsl:param name="output_dir" select="'data/json'"/>

  <xsl:variable name="extracted" select="//ons:dataPackage/msg:CrossSectionalData/msg:Header/msg:Extracted"/>
  <xsl:variable name="published" select="substring-before($extracted, 'T')"/>
  <xsl:variable name="dataset-id" select="replace( lower-case(//ons:dataPackage/msg:CrossSectionalData/msg:Header/msg:DataSetID), '_', '-')"/>
  
  <xsl:template match="ons:dataPackage">
    <xsl:text>{  
      "coverage": "http://statistics.data.gov.uk/doc/statistical-geography/K02000001",
      "geographic-breakdown": "UK and GB",
      "notes": "&lt;p>&lt;strong>Important Note for Users&lt;/strong>&lt;/p>&lt;p>All of the data included in this dataset is published on a 2010=100 basis.&lt;/p>&lt;p>A comprehensive selection of data on input and output indices. Contains producer price indices of materials and fuels purchased and output of manufacturing industry by broad sector.&lt;/p>&lt;p>Indices for the latest two months are provisional due to the level of imputation present for items where the latest prices are not available. The latest five months are subject to revisions in light of (a) late and revised contributor data and (b) revisions to seasonal adjustment factors which are re-estimated every month.&lt;/p>",
      </xsl:text>
      <!-- title -->
      <xsl:apply-templates select="msg:CrossSectionalData/wdp:DataSet/wdp:Group" />  
      <!-- metadata -->
      <xsl:apply-templates select="msg:CrossSectionalData/msg:Header" />      
      <!-- structure -->
      <xsl:apply-templates select="msg:Structure" />
      
    <xsl:text>}</xsl:text>  
  </xsl:template>

  <xsl:template match="wdp:Group">
      <xsl:variable name="pub" select="@Publication"/>
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'title'"/>
        <xsl:with-param name="value">
          <xsl:value-of select="//structure:Code[@value=$pub]/structure:Description"/>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:text>,</xsl:text>      
  </xsl:template>
  
  <xsl:template match="msg:CrossSectionalData/msg:Header">    
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'id'"/>
        <xsl:with-param name="value" select="concat('/statistics/producer-price-index/', $published,'/', $dataset-id)"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'type'"/>
        <xsl:with-param name="value" select="'DataSet'"/>
      </xsl:call-template> 

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'release'"/>
        <xsl:with-param name="value" select="concat('/statistics/producer-price-index/', $published)"/>
      </xsl:call-template> 

      <xsl:text>,</xsl:text>
  
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'contact'"/>
        <xsl:with-param name="value">
              <xsl:apply-templates select="msg:Sender/msg:Contact"/>
        </xsl:with-param>
        <xsl:with-param name="string" select="false()"/>
      </xsl:call-template>
      
      <xsl:text>,</xsl:text>
        
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'published'"/>
        <xsl:with-param name="value" select="$extracted"/>
      </xsl:call-template>
    
  </xsl:template>

  <xsl:template match="msg:Contact">
    <xsl:text>{</xsl:text>  
      <xsl:for-each select="msg:*">
        <xsl:call-template name="json-key">
          <xsl:with-param name="name" select="lower-case(local-name())" />
          <xsl:with-param name="value" select="."/>
        </xsl:call-template> 
        <xsl:if test="position() != last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>    
    <xsl:text>}</xsl:text>
  </xsl:template>
      
  <xsl:template match="msg:Structure">
    <xsl:text>,</xsl:text>
    <xsl:call-template name="json-key">
      <xsl:with-param name="name" select="'structure'" />
      <xsl:with-param name="value">
        <xsl:text>{
          "provisional": {
            "id": "/def/quality/provisional",
            "type": "attribute",
            "title": "Provisional"
          },
          "revised": {
            "id": "/def/quality/revised",
            "type": "attribute",
            "title": "Revised"          
          },
          "unreliable": {
            "id": "/def/quality/unreliable",
            "type": "attribute",
            "title": "Unreliable",
            "values": { "coverage": {
                "id": "/def/quality/unreliable/coverage",
                "notation": "coverage",
                "title": "Limited Coverage" 
              }
            }          
          },          
        </xsl:text>
        <xsl:for-each select="//structure:Components/structure:Dimension|//structure:Components/structure:TimeDimension|//structure:Components/structure:PrimaryMeasure|//structure:Components/structure:Attribute">
          <xsl:apply-templates select="."/>
          <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
          </xsl:if>      
        </xsl:for-each>
        <xsl:text>}</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="string" select="false()"/>      
    </xsl:call-template> 
  </xsl:template>
  
  <xsl:template match="structure:Dimension|structure:TimeDimension|structure:PrimaryMeasure|structure:Attribute">
    <xsl:variable name="dimension-name">
      <xsl:choose>
        <xsl:when test="lower-case( @conceptRef ) = 'obs_value'">
          <xsl:value-of select="'price_index'"/>
        </xsl:when>
        <xsl:when test="lower-case( @conceptRef ) = 'cdid'">
          <xsl:value-of select="'product'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case( @conceptRef )"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="json-key">
      <xsl:with-param name="name" select="$dimension-name"/>     
      <xsl:with-param name="string" select="false()"/>       
      <xsl:with-param name="value">
        <xsl:text>{</xsl:text>
          <xsl:call-template name="json-key">
            <xsl:with-param name="name" select="'id'"/>
            <xsl:with-param name="value" select="concat( '/def/producer-price-index/', $dimension-name )"/>
          </xsl:call-template>
          <xsl:text>,</xsl:text>
          <xsl:call-template name="json-key">
            <xsl:with-param name="name" select="'type'"/>
            <xsl:with-param name="value" select="lower-case(local-name())"/>
          </xsl:call-template>
          <xsl:text>,</xsl:text>
          <xsl:variable name="conceptRef" select="@conceptRef"/>
          <xsl:call-template name="json-key">
            <xsl:with-param name="name" select="'title'"/>
            <xsl:with-param name="value" select="//structure:Concept[@id=$conceptRef]/structure:Name"/>
          </xsl:call-template>
          
          <xsl:if test="//structure:CodeList[@id=$conceptRef]">
            <xsl:text>,</xsl:text>

            <xsl:call-template name="json-key">
              <xsl:with-param name="name" select="'values'"/>
              <xsl:with-param name="string" select="false()"/>
              <xsl:with-param name="value">
                 <xsl:text>{</xsl:text>
	             <xsl:for-each select="//structure:CodeList[@id=$conceptRef]/structure:Code">
                  <xsl:apply-templates select="."/>
                  <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                  </xsl:if>                    
                  </xsl:for-each>
                 <xsl:text>}</xsl:text>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          
        <xsl:text>}</xsl:text>        
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="structure:Code">
    <xsl:call-template name="json-key">
      <xsl:with-param name="name" select="@value"/>
      <xsl:with-param name="string" select="false"/>
      <xsl:with-param name="value">
          <xsl:text>{</xsl:text>
      
          <xsl:call-template name="json-key">
            <xsl:with-param name="name" select="'notation'"/>
            <xsl:with-param name="value" select="@value"/>
          </xsl:call-template>
          
          <xsl:text>,</xsl:text>
      
          <xsl:call-template name="json-key">
            <xsl:with-param name="name" select="'id'"/>
            <xsl:with-param name="value" select="concat( '/def/producer-price-index/', lower-case(../@id), '/', lower-case(@value) )"/>
          </xsl:call-template>
          
          <xsl:text>,</xsl:text>
          
          <xsl:call-template name="json-key">
            <xsl:with-param name="name" select="'title'"/>
            <xsl:with-param name="value" select="structure:Description"/>
          </xsl:call-template>
          <xsl:text>}</xsl:text>    
      
      </xsl:with-param>    
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="*" />

  <xsl:template name="json-key">
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <xsl:param name="string" select="true()"/>
    <xsl:text>"</xsl:text><xsl:value-of select="$name"/><xsl:text>":</xsl:text><xsl:if test="$string"><xsl:text>"</xsl:text></xsl:if><xsl:value-of select="$value"/><xsl:if test="$string"><xsl:text>"</xsl:text></xsl:if>
  </xsl:template>
  
</xsl:stylesheet>