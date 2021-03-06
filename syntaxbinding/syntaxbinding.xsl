<?xml version="1.0" encoding="utf-8"?>
<!--
The MIT License (MIT)

Copyright (c) 2013 Veit Jahns

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
-->
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:sb="http://www.bmecat.org/syntaxbinding/2013"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:owl="http://www.w3.org/2002/07/owl#">

<xsl:output method="text"/>
<xsl:param name="root">BMECAT</xsl:param>
<xsl:param name="ontology-file">BiiTrdm019-Catalogue.rdf</xsl:param>

<xsl:variable name="ontology" select="document($ontology-file)" />

<xsl:template match="/">
	<xsl:apply-templates select="//xsd:element[@name=$root]" />
</xsl:template>

<xsl:template name="get-first-token">
	<!--
		Returns the first token from $string or while $string is a
		whitespace separated tokenlist.
	-->	
	
	<xsl:param name="string" />
	
	<xsl:choose>
		<xsl:when
			test="substring-before($string, ' ')=''">
			<xsl:value-of select="$string" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="substring-before($string, ' ')" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="resolve-curi">
	<!--
		Resolves a CURI ($curi) to a complete URI.
	-->
	
	<xsl:param name="curi" select="''" />
	
	<xsl:variable
		name="prefix"
		select="substring-before($curi, ':')" />
	
	<xsl:variable
		name="namespace-uri"
		select="/xsd:schema/xsd:annotation/xsd:appinfo/sb:namespace[sb:prefix=$prefix]/sb:uri" />

	<xsl:value-of
		select="
			concat(
				$namespace-uri,
				substring-after($curi, ':'))" />
</xsl:template>

<xsl:template name="get-curi">
	<!-- Gets the curi part of a curi-predicate expression -->
	
	<xsl:param name="expression" />
	
	<xsl:choose>
		<xsl:when test="contains($expression, '[')">
		<xsl:value-of
			select=" substring-before($expression, '[')" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$expression" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="get-predicate">
	<!-- Gets the predicate of a curi-predicate expression -->
	
	<xsl:param name="expression" />
	
	<xsl:if test="contains($expression, '[')">
		<xsl:text>[</xsl:text>
		<xsl:value-of
			select="
				substring-before(
					substring-after($expression, '['),
					']')" />
		<xsl:text>]</xsl:text>
	</xsl:if>
</xsl:template>

<xsl:template name="write-path">
	<!--
		Writes the syntax binding XPath for the properties specified
		in $property and $remaining-properties.
	-->

	<xsl:param name="path" />
	<xsl:param name="property" />
	<xsl:param name="remaining-properties" />
	<xsl:param name="current-concept" select="''" />
	<xsl:param name="content" select="''" />
	<xsl:param name="comment" select="''" />
	
	<!-- Write property binding -->
	<xsl:if test="$property!=''">
					
		<xsl:variable name="current-concept-uri">
			<xsl:call-template name="resolve-curi">
				<xsl:with-param name="curi" select="$current-concept" />
			</xsl:call-template>
		</xsl:variable>
		
		<!-- CURI of the property -->
		<xsl:variable name="property-curi">
			<xsl:call-template name="get-curi">
				<xsl:with-param
					name="expression"
					select="$property" />
			</xsl:call-template>
		</xsl:variable>
		
		<!-- Resolved URI of the property -->
		<xsl:variable name="property-uri">
			<xsl:call-template name="resolve-curi">
				<xsl:with-param name="curi" select="$property-curi" />
			</xsl:call-template>
		</xsl:variable>
		
		<!-- Predicate for the property -->
		<xsl:variable name="property-predicate">
			<xsl:call-template name="get-predicate">
				<xsl:with-param
					name="expression"
					select="$property" />
			</xsl:call-template>
		</xsl:variable>

		<!--
			The concept the property belongs to, i.e. the domain of the
			property.
		-->
		<xsl:variable
			name="property-concept"
			select="
				$ontology/rdf:RDF/rdf:Description[
					@rdf:about=$property-uri
				]/rdfs:domain/@rdf:resource" />
	
		<!--
			Only print, if the the current concept is the domain of
			property.
		-->		
		<xsl:if test="$property-concept=$current-concept-uri">
			<xsl:value-of select="$property-curi" />
			<xsl:text>;</xsl:text>
			<xsl:value-of select="$current-concept-uri" />
			<xsl:text>;</xsl:text>
			<!-- Print the XPath for the property element -->
			<xsl:value-of select="$path" />
			<xsl:text>/</xsl:text>
			<xsl:if
				test="
					local-name()='attribute'
						and namespace-uri()='http://www.w3.org/2001/XMLSchema'">
				<xsl:text>@</xsl:text>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@ref">
					<xsl:value-of select="@ref" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@name" />
				</xsl:otherwise>
			</xsl:choose>
			<!-- Print predicate for the property element -->
			<xsl:if test="$property-predicate!=''">
				<xsl:value-of select="$property-predicate" />
			</xsl:if>
			<!-- Print content of the property element -->
			<xsl:text>;</xsl:text>
			<xsl:if test="$content!=''">
				<xsl:text>"</xsl:text>
				<xsl:value-of select="$content" />
				<xsl:text>"</xsl:text>
			</xsl:if>
			<xsl:text>;</xsl:text>
			<xsl:if test="$comment!=''">
				<xsl:text>&quot;</xsl:text>
				<xsl:value-of select="$comment" />
				<xsl:text>&quot;</xsl:text>
			</xsl:if>
			<xsl:text>
</xsl:text>
		</xsl:if>
	</xsl:if>

	<!-- Write remaining property bindings -->
	<xsl:if test="$remaining-properties!=''">
		
		<xsl:variable name="next-property">
			<xsl:call-template name="get-first-token">
				<xsl:with-param
					name="string"
					select="$remaining-properties" />
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:call-template name="write-path">
			<xsl:with-param name="path" select="$path" />
			<xsl:with-param
				name="property"
				select="$next-property" />
			<xsl:with-param
				name="remaining-properties"
				select="substring-after($remaining-properties, ' ')" />
			<xsl:with-param
				name="current-concept"
				select="$current-concept" />
			<xsl:with-param
				name="comment"
				select="@sb:comment" />
		</xsl:call-template>
	</xsl:if>
	
</xsl:template>

<xsl:template name="is-part-of">
	<xsl:param name="super-concept" />
	<xsl:param name="sub-concept" />
	
	<xsl:variable name="super-concept-uri">
		<xsl:call-template name="resolve-curi">
			<xsl:with-param name="curi" select="$super-concept" />
		</xsl:call-template>
	</xsl:variable>
	
	<xsl:variable name="sub-concept-uri">
		<xsl:call-template name="resolve-curi">
			<xsl:with-param name="curi" select="$sub-concept" />
		</xsl:call-template>
	</xsl:variable>
	
	<xsl:variable name="by-range">
		<xsl:choose>
			<xsl:when
				test="
					$ontology/rdf:RDF/rdf:Description[
						rdfs:range/@rdf:resource=$sub-concept-uri
					]/@rdf:about">
				<!-- Only one statement on the property -->
				<xsl:value-of
					select="
						$ontology/rdf:RDF/rdf:Description[
							rdfs:range/@rdf:resource=$sub-concept-uri
						]/@rdf:about" />
			</xsl:when>
			<xsl:otherwise>
				<!-- More then one statement via rdf:nodeID -->
				<xsl:variable
					name="node-id"
					select="
						$ontology/rdf:RDF/rdf:Description[
							owl:onClass/@rdf:resource=$sub-concept-uri
						]/@rdf:nodeID" />
				<xsl:value-of
					select="
						$ontology/rdf:RDF/rdf:Description[
							rdfs:range/@rdf:nodeID=$node-id
						]/@rdf:about" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
		
	<xsl:choose>
		<xsl:when test="$super-concept=''">
			<!--
				$super-concept is empty. Empty means the world and
				everything is part of the world.
			-->
			<xsl:text>true</xsl:text>
		</xsl:when>
		<xsl:when test="$super-concept=$sub-concept">
			<!--
				$super-concept is equal to $sub-concept. Everything
				is part of itself.
			-->
			<xsl:text>true</xsl:text>
		</xsl:when>
		<xsl:when
			test="
				$ontology/rdf:RDF/rdf:Description[
					@rdf:about=$by-range
				]/rdf:type[
					@rdf:resource='http://www.w3.org/2002/07/owl#ObjectProperty'
				]">
			<!--
				$by-range is an object property with $sub-concept as
				range. Now check, if $super-concept is a domain of this
				object property.
			-->
			<xsl:variable
				name="by-domain"
				select="
					$ontology/rdf:RDF/rdf:Description[
						rdfs:domain/@rdf:resource=$super-concept-uri
							and @rdf:about=$by-range
					]/@rdf:about" />
			<xsl:if test="$by-domain=$by-range">
				<!--
					Yes, $sub-concept is part of $super-concept.
				-->				
				<xsl:text>true</xsl:text>
			</xsl:if>
		</xsl:when>
		<xsl:otherwise />
	</xsl:choose>
	
</xsl:template>

<xsl:template name="iterate-typeofs">
	<xsl:param name="name" />
	<xsl:param name="typeof" />
	<xsl:param name="remaining-typeofs" />
	<xsl:param name="path" />
	<xsl:param name="current-concept" />
	<xsl:param name="predicate" />

	<!-- Bind the concept -->
	<xsl:if test="$typeof!=''">
			
		<xsl:variable name="typeof-predicate">
			<xsl:call-template name="get-predicate">
				<xsl:with-param name="expression" select="$typeof" />
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="new-current-concept">
			<xsl:call-template name="get-curi">
				<xsl:with-param name="expression" select="$typeof" />
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="super-concept">
			<xsl:choose>
				<xsl:when test="@sb:domain">
					<xsl:value-of select="@sb:domain" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$current-concept" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="in-range">
			<xsl:call-template name="is-part-of">
				<xsl:with-param
					name="super-concept"
					select="$super-concept" />
				<xsl:with-param
					name="sub-concept"
					select="$new-current-concept" />
			</xsl:call-template>
		</xsl:variable>

		<xsl:if test="$in-range='true'">
						
			<xsl:if test="@sb:property">
				<xsl:call-template name="bind-property">
					<xsl:with-param 
						name="properties"
						select="@sb:property" />
					<xsl:with-param
						name="path"
						select="$path" />
					<xsl:with-param
						name="current-concept"
						select="$new-current-concept" />
					<xsl:with-param
						name="content"
						select="@sb:content" />
				</xsl:call-template>			
			</xsl:if>
			
			<xsl:choose>
				<xsl:when test="@ref">
					
					<xsl:apply-templates select="//xsd:element[@name=$name]">
						<xsl:with-param
							name="path"
							select="$path" />
						<xsl:with-param
							name="predicate"
							select="$typeof-predicate" />
						<xsl:with-param
							name="current-concept"
							select="$new-current-concept" />
					</xsl:apply-templates>
					
				</xsl:when>
				<xsl:when test="@type">
					
					<xsl:variable name="type" select="@type" />
					
					<xsl:apply-templates select="//xsd:complexType[@name=$type]">
						<xsl:with-param
							name="path"
							select="concat($path, '/', $name, $predicate)" />
						<xsl:with-param
							name="predicate"
							select="$typeof-predicate" />
						<xsl:with-param name="current-concept">
							<xsl:choose>
								<xsl:when test="contains($typeof, '[')">
								<xsl:value-of
									select=" substring-before($typeof, '[')" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$typeof" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
					</xsl:apply-templates>
					
				</xsl:when>
				<xsl:otherwise>
					
					<xsl:apply-templates select="xsd:complexType">
						<xsl:with-param
							name="path"
							select="concat($path, '/', $name, $predicate)" />
						<xsl:with-param
							name="predicate"
							select="$typeof-predicate" />
						<xsl:with-param name="current-concept">
							<xsl:choose>
								<xsl:when test="contains($typeof, '[')">
									<xsl:value-of
										select=" substring-before($typeof, '[')" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$typeof" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
					</xsl:apply-templates>		
							
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		
	</xsl:if>

	<!-- Bind remaining concepts -->
	<xsl:if test="$remaining-typeofs!=''">
		
		<xsl:variable name="nextTypeof">
			<xsl:call-template name="get-first-token">
				<xsl:with-param
					name="string"
					select="$remaining-typeofs" />
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:call-template name="iterate-typeofs">
			<xsl:with-param name="name" select="$name" />
			<xsl:with-param name="typeof" select="$nextTypeof" />
			<xsl:with-param
				name="remaining-typeofs"
				select="substring-after($remaining-typeofs, ' ')" />
			<xsl:with-param name="path" select="$path" />
			<xsl:with-param
				name="current-concept"
				select="$current-concept" />
		</xsl:call-template>
		
	</xsl:if>
					
</xsl:template>

<xsl:template name="bind-property">
	<xsl:param name="properties" select="''" />
	<xsl:param name="path" select="''" />
	<xsl:param name="current-concept" select="''" />
	<xsl:param name="content" select="''" />
	<xsl:param name="comment" select="''" />
	
	<xsl:variable name="property">
		<xsl:call-template name="get-first-token">
			<xsl:with-param
				name="string"
				select="$properties" />
		</xsl:call-template>
	</xsl:variable>
	
	<xsl:call-template name="write-path">
		<xsl:with-param name="path" select="$path" />
		<xsl:with-param
			name="property"
			select="$property" />
		<xsl:with-param
			name="remaining-properties"
			select="substring-after($properties, ' ')" />
		<xsl:with-param
			name="current-concept"
			select="$current-concept" />
		<xsl:with-param
			name="content"
			select="$content" />
		<xsl:with-param
			name="comment"
			select="$comment" />
	</xsl:call-template>
</xsl:template>

<xsl:template match="xsd:element[count(@*[local-name()='property'])=1]">
	<xsl:param name="path" />
	<xsl:param name="current-concept" select="''" />
	
	<xsl:variable
		name="properties"
		select="string(@*[local-name()='property'])" />

	<xsl:call-template name="write-path">
		<xsl:with-param name="path" select="$path" />
		<xsl:with-param
			name="property"
			select="substring-before($properties, ' ')" />
		<xsl:with-param
			name="remaining-properties"
			select="substring-after($properties, ' ')" />
		<xsl:with-param
			name="current-concept"
			select="$current-concept" />
	</xsl:call-template>
	
</xsl:template>

<xsl:template match="xsd:element[count(@name)=1 and count(@ref)=0]">
	<xsl:param name="path" />
	<xsl:param name="predicate" select="''" />
	<xsl:param name="current-concept" select="''" />
	
	<xsl:variable name="type" select="@type" />
	<xsl:variable name="name" select="@name" />
			
	<xsl:if test="@sb:property">
		
		<xsl:call-template name="bind-property">
			<xsl:with-param 
				name="properties"
				select="@sb:property" />
			<xsl:with-param
				name="path"
				select="$path" />
			<xsl:with-param
				name="current-concept"
				select="$current-concept" />
			<xsl:with-param
				name="content"
				select="@sb:content" />
			<xsl:with-param
				name="comment"
				select="@sb:comment" />
		</xsl:call-template>
		
	</xsl:if>
	
	<xsl:choose>
		<xsl:when test="@sb:typeof">
			
			<xsl:variable name="typeof">
				<xsl:call-template name="get-first-token">
					<xsl:with-param
						name="string"
						select="@sb:typeof" />
				</xsl:call-template>
			</xsl:variable>

			<xsl:call-template name="iterate-typeofs">
				<xsl:with-param name="name" select="$name" />
				<xsl:with-param name="typeof" select="$typeof" />
				<xsl:with-param
					name="remaining-typeofs"
					select="substring-after(@sb:typeof, ' ')" />
				<xsl:with-param
					name="path"
					select="$path" />
				<xsl:with-param
					name="name"
					select="$name" />
				<xsl:with-param
					name="predicate"
					select="$predicate" />
				<xsl:with-param
					name="current-concept"
					select="$current-concept" />
			</xsl:call-template>
			
		</xsl:when>
		<xsl:otherwise>
			<xsl:choose>
				<xsl:when test="xsd:complexType">
					
					<xsl:apply-templates select="xsd:complexType">
						<xsl:with-param
							name="path"
							select="concat($path, '/', $name, $predicate)" />
						<xsl:with-param
							name="current-concept"
							select="$current-concept" />
					</xsl:apply-templates>
					
				</xsl:when>
				<xsl:otherwise>
					<!--
						Script is not able to handle loops in the schema
						definition. Thus, only some complex types are
						considered.
					-->
					<xsl:if
						test="
							starts-with($type, 'udx')
								or $type='typeADDRESS'
								or $type='typeFTEMPLATE'">
						<xsl:apply-templates select="//xsd:complexType[@name=$type]">
							<xsl:with-param
								name="path"
								select="concat($path, '/', $name, $predicate)" />
							<xsl:with-param
								name="current-concept"
								select="$current-concept" />
						</xsl:apply-templates>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
		
</xsl:template>

<xsl:template match="xsd:element[count(@name)=0 and count(@ref)=1]">
	<xsl:param name="path" />
	<xsl:param name="current-concept" select="''" />
	
	<xsl:variable name="ref" select="@ref" />
	
	<xsl:if test="@sb:property">

		<xsl:call-template name="bind-property">
			<xsl:with-param 
				name="properties"
				select="@sb:property" />
			<xsl:with-param
				name="path"
				select="$path" />
			<xsl:with-param
				name="current-concept"
				select="$current-concept" />
			<xsl:with-param
				name="content"
				select="@sb:content" />
			<xsl:with-param
				name="comment"
				select="@sb:comment" />
		</xsl:call-template>

	</xsl:if>
			
	<xsl:choose>
		<xsl:when test="@sb:typeof">
			
			<xsl:variable name="typeof">
				<xsl:call-template name="get-first-token">
					<xsl:with-param
						name="string"
						select="@sb:typeof" />
				</xsl:call-template>
			</xsl:variable>
				
			<xsl:call-template name="iterate-typeofs">
				<xsl:with-param name="name" select="$ref" />
				<xsl:with-param name="typeof" select="$typeof" />
				<xsl:with-param
					name="remaining-typeofs"
					select="substring-after(@sb:typeof, ' ')" />
				<xsl:with-param name="path" select="$path" />
				<xsl:with-param
					name="current-concept"
					select="$current-concept" />
			</xsl:call-template>
			
		</xsl:when>
		<xsl:otherwise>
			
			<xsl:apply-templates select="//xsd:element[@name=$ref]">
				<xsl:with-param
					name="path"
					select="$path" />
				<xsl:with-param
					name="current-concept"
					select="$current-concept" />
			</xsl:apply-templates>
			
		</xsl:otherwise>
	</xsl:choose>
		
</xsl:template>

<xsl:template match="xsd:attribute">
	<xsl:param name="path" />
	<xsl:param name="current-concept" select="''" />

	<xsl:if test="@sb:property">
		<xsl:call-template name="bind-property">
			<xsl:with-param
				name="properties"
				select="@sb:property" />
			<xsl:with-param
				name="path"
				select="$path" />
			<xsl:with-param
				name="current-concept"
				select="$current-concept" />
			<xsl:with-param
				name="content"
				select="@sb:content" />
		</xsl:call-template>		
	</xsl:if>
	
</xsl:template>

<xsl:template match="xsd:complexType|xsd:sequence|xsd:choice">
	<xsl:param name="path" />
	<xsl:param name="predicate" select="''" />
	<xsl:param name="current-concept" select="''" />
	
	<xsl:apply-templates
		select="
			xsd:complexType
				| xsd:sequence
				| xsd:choice
				| xsd:element
				| xsd:attribute">
		<xsl:with-param name="path" select="$path" />
		<xsl:with-param name="predicate" select="$predicate" />
		<xsl:with-param
			name="current-concept"
			select="$current-concept" />
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="*|@*">
</xsl:template>

</xsl:stylesheet>
