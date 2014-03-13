<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="2.0" 
  xmlns:msg="http://www.SDMX.org/resources/SDMXML/schemas/v2_0/message"
  xmlns:ons="http://www.ons.gov.uk/schemas"
  xmlns:structure="http://www.SDMX.org/resources/SDMXML/schemas/v2_0/structure"
  xmlns:wdp="urn:sdmx:org.sdmx.infomodel.keyfamily.KeyFamily=ONS:PPI_CSDB_DS:1.0:cross">

  <xsl:output name="text" method="text" />

  <xsl:param name="output_dir" select="'data/json'"/>

  <xsl:variable name="extracted" select="//ons:dataPackage/msg:CrossSectionalData/msg:Header/msg:Extracted"/>
  <xsl:variable name="published" select="substring-before($extracted, 'T')"/>
  
  <xsl:variable name="dataset-slug" select="replace( lower-case(//ons:dataPackage/msg:CrossSectionalData/msg:Header/msg:DataSetID), '_', '-')"/>
  
  <xsl:variable name="series-id" select="'/statistics/producer-price-index'"/>
  <xsl:variable name="release-id" select="concat( '/statistics/producer-price-index/', $published )"/>  
  <xsl:variable name="dataset-id" select="concat( '/statistics/producer-price-index/', $published, '/', $dataset-slug )"/>
  
  <xsl:template match="ons:dataPackage">
    <xsl:apply-templates select="msg:CrossSectionalData" />
  </xsl:template>

  <xsl:template match="msg:CrossSectionalData">
    <xsl:apply-templates select="wdp:DataSet" />
  </xsl:template>

  <xsl:template match="wdp:DataSet">
    <xsl:apply-templates select="wdp:Group" />
  </xsl:template>

  <xsl:template match="wdp:Group">
    <xsl:apply-templates select="wdp:Section" />
  </xsl:template>

<!-- 
  <xsl:variable name="exclude" select="tokenize('2014JAN', ',\s+')"/>
  <xsl:variable name="uncertain" select="tokenize('2013DEC,2014JAN', ',\s+')"/>
 -->
  
  <xsl:template match="wdp:Section">
  <!-- 
    <xsl:apply-templates select="wdp:*[../@Date != $exclude]" />
     -->
    <xsl:apply-templates select="wdp:*" />     
  </xsl:template>

  <xsl:template match="wdp:Section/wdp:*">
    <xsl:variable name="slug" select="concat( lower-case( local-name() ), '-', lower-case( ../@Date )  )"/>
    <xsl:variable name="filename"
      select="concat( $output_dir, '/', $slug, '.json')" />

    <xsl:message><xsl:value-of select="$filename"/></xsl:message>
    
    <xsl:result-document href="{$filename}" format="text">
      <xsl:text>{</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'id'"/>
        <xsl:with-param name="value" select="concat( $dataset-id, '/', $slug )"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>
      
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'type'"/>
        <xsl:with-param name="value" select="'Observation'"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'release'"/>
        <xsl:with-param name="value" select="$release-id"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'series'"/>
        <xsl:with-param name="value" select="$series-id"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>      
      
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'published'"/>
        <xsl:with-param name="value" select="$extracted"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'dataset'"/>
        <xsl:with-param name="value" select="$dataset-id"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <!-- TODO: leave this as cdid, or alternate name? -->
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'cdid'"/>
        <xsl:with-param name="value" select="local-name()"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'date'"/>
        <xsl:with-param name="value" select="../@Date"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'base_period'"/>
        <xsl:with-param name="value" select="@base_period"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'price'"/>
        <xsl:with-param name="value" select="@price"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'seasonal_adjustment'"/>
        <xsl:with-param name="value" select="@seasonal_adjustment"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'index_period'"/>
        <xsl:with-param name="value" select="@index_period"/>
      </xsl:call-template>

      <xsl:text>,</xsl:text>

      <!-- add provisional indicator for most recent two months -->
      <xsl:variable name="provisional">
        <xsl:choose>
          <xsl:when test="../@Date = '2014JAN' or ../@Date = '2013DEC'">
            <xsl:value-of select="'true'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'false'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'provisional'" />
        <xsl:with-param name="value" select="$provisional" />
        <xsl:with-param name="string" select="false()" />
      </xsl:call-template>
    
      <xsl:text>,</xsl:text>      
      
      <!-- add some revision markers -->
      <!--  2013SEP 2013OCT: MC3W, MC3X, MC3V, MC42  -->
      <xsl:if test="(../@Date = '2013SEP' or ../@Date = '2013OCT') and local-name() = ('MC3W', 'MC3X', 'MC3V', 'MC42')">
        <xsl:call-template name="json-key">
          <xsl:with-param name="name" select="'revised'"/>
          <xsl:with-param name="value" select="'true'"/>
          <xsl:with-param name="string" select="false()"/>
        </xsl:call-template>

        <xsl:text>,</xsl:text>      
      </xsl:if>

      <xsl:if test="../@Date = ('2013SEP','2013OCT','2013NOV','2013DEC', '2014JAN') and local-name() = ('MC6A','JU5C')">
        <xsl:call-template name="json-key">
          <xsl:with-param name="name" select="'unreliable'"/>
          <xsl:with-param name="value" select="'coverage'"/>
          <xsl:with-param name="string" select="false()"/>
        </xsl:call-template>

        <xsl:text>,</xsl:text>      
      </xsl:if>      

      <xsl:call-template name="json-key">
        <xsl:with-param name="name" select="'obs_value'"/>
        <xsl:with-param name="value" select="@value"/>
        <xsl:with-param name="string" select="false()"/>
      </xsl:call-template>
          
      <xsl:text>}</xsl:text>
    
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="*" />

  <xsl:template name="json-key">
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <xsl:param name="string" select="true()"/>
    <xsl:text>"</xsl:text><xsl:value-of select="$name"/><xsl:text>":</xsl:text><xsl:if test="$string"><xsl:text>"</xsl:text></xsl:if><xsl:value-of select="$value"/><xsl:if test="$string"><xsl:text>"</xsl:text></xsl:if>
  </xsl:template>
  
</xsl:stylesheet>