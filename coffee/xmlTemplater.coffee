encode_utf8 = (s)->
	unescape(encodeURIComponent(s))

decode_utf8= (s) ->
	decodeURIComponent(escape(s)).replace(new RegExp(String.fromCharCode(160),"g")," ") #replace Ascii 160 space by the normal space, Ascii 32

String.prototype.replaceFirstFrom = (search,replace,from) ->  #replace first occurence of search (can be regex) after *from* offset
	this.substr(0,from)+this.substr(from).replace(search,replace)

preg_match_all= (regex, content) -> 
	###regex is a string, content is the content. It returns an array of all matches with their offset, for example: 
	regex=la
	content=lolalolilala
	returns: [{0:'la',offset:2},{0:'la',offset:8},{0:'la',offset:10}]
	###
	matchArray= []
	replacer = (match,pn ..., offset, string)->
		pn.unshift match #add match so that pn[0] = whole match, pn[1]= first parenthesis,...
		pn.offset= offset
		matchArray.push pn
	content.replace (new RegExp(regex,'g')),replacer
	matchArray

window.XmlTemplater = class XmlTemplater
	constructor: (content="",@templateVars={},@intelligentTagging=off) ->
		if typeof content=="string" then @load content else throw "content must be string!"
		@currentScope=@templateVars
	load: (@content) ->
		@matches = @_getFullTextMatchesFromData()
		@charactersAdded= (0 for i in [0...@matches.length])
		replacer = (match,pn ..., offset, string)=>
			pn.unshift match #add match so that pn[0] = whole match, pn[1]= first parenthesis,...
			pn.offset= offset
			@matches.unshift pn #add at the beginning
			@charactersAdded.unshift 0
		@content.replace /^()([^<]+)/,replacer
	getValueFromTag: (tag,scope) ->
		if scope[tag]? then return encode_utf8 scope[tag] else return "undefined"
	calcScopeText: (text,start=0,end=text.length-1) -> 
		###get the different closing and opening tags between two texts (doesn't take into account tags that are opened then closed (those that are closed then opened are returned)): 
		returns:[{"tag":"</w:r>","offset":13},{"tag":"</w:p>","offset":265},{"tag":"</w:tc>","offset":271},{"tag":"<w:tc>","offset":828},{"tag":"<w:p>","offset":883},{"tag":"<w:r>","offset":1483}] 
		###
		tags= preg_match_all("<(\/?[^/> ]+)([^>]*)>",text.substr(start,end)) #getThemAll (the opening and closing tags)!
		result=[]
		for tag,i in tags
			if tag[1][0]=='/' #closing tag
				justOpened= false 
				if result.length>0
					lastTag= result[result.length-1]
					innerLastTag= lastTag.tag.substr(1,lastTag.tag.length-2)
					innerCurrentTag= tag[1].substr(1)
					if innerLastTag==innerCurrentTag then justOpened= true #tag was just opened
				if justOpened then result.pop() else result.push {tag:'<'+tag[1]+'>',offset:tag.offset}
			else if tag[2][tag[2].length-1]=='/' #open/closing tag aren't taken into account(for example <w:style/>)
			else	#opening tag
				result.push {tag:'<'+tag[1]+'>',offset:tag.offset}
		result

	calcScopeDifference: (text,start=0,end=text.length-1) -> #it returns the difference between two scopes, ie simplifyes closes and opens. If it is not null, it means that the beginning is for example in a table, and the second one is not. If you hard copy this text, the XML will  break
		scope= @calcScopeText text,start,end
		while(1)
			if (scope.length<=1) #if scope.length==1, then they can't be an opeining and closing tag 
				break;
			if ((scope[0]).tag.substr(2)==(scope[scope.length-1]).tag.substr(1)) #if the first closing is the same than the last opening, ie: [</tag>,...,<tag>]
				scope.pop() #remove both the first and the last one 
				scope.shift()
			else break;
		scope
	getFullText:() ->
		@matches= @_getFullTextMatchesFromData() #get everything that is between <w:t>
		output= (match[2] for match in @matches) #get only the text
		decode_utf8(output.join("")) #join it
	_getFullTextMatchesFromData: () ->
		@matches= preg_match_all("(<w:t[^>]*>)([^<>]*)?</w:t>",@content)
	calcInnerTextScope: (text,start,end,tag) -> #tag: w:t
		endTag= text.indexOf('</'+tag+'>',end)
		if endTag==-1 then throw "can't find endTag #{endTag}"
		endTag+=('</'+tag+'>').length
		startTag = Math.max text.lastIndexOf('<'+tag+'>',start), text.lastIndexOf('<'+tag+' ',start)
		if startTag==-1 then throw "can't find startTag"
		{"text":text.substr(startTag,endTag-startTag),startTag,endTag}
	calcB: () ->
		startB = @calcStartBracket @loopOpen
		endB= @calcEndBracket @loopClose
		{B:@content.substr(startB,endB-startB),startB,endB}
	calcA: () ->
		startA= @calcEndBracket @loopOpen
		endA= @calcStartBracket @loopClose
		{A:@content.substr(startA,endA-startA),startA,endA}
	calcStartBracket: (bracket) ->
		@matches[bracket.start.i].offset+@matches[bracket.start.i][1].length+@charactersAdded[bracket.start.i]+bracket.start.j
	calcEndBracket: (bracket)->
		@matches[bracket.end.i].offset+@matches[bracket.end.i][1].length+@charactersAdded[bracket.end.i]+bracket.end.j+1
	forLoop: () ->
		###
			<w:t>{#forTag} blabla</w:t>
			Blabla1
			Blabla2
			<w:t>{/forTag}</w:t>

			Let A be what is in between the first closing bracket and the second opening bracket
			Let B what is in between the first opening tag {# and the last closing tag
			
			A=</w:t>
			Blabla1
			Blabla2
			<w:t>

			B={#forTag}</w:t>
			Blabla1
			Blabla2
			<w:t>{/forTag}

			We replace B by nA, n is equal to the length of the array in scope forTag
			<w:t>subContent subContent subContent</w:t>
		###

		B= @calcB().B
		A= @calcA().A

		if B[0]!='{' or B.indexOf('{')==-1 or B.indexOf('/')==-1 or B.indexOf('}')==-1 or B.indexOf('#')==-1 then throw "no {,#,/ or } found in B: #{B}"

		if @currentScope[@loopOpen.tag]?
			if typeof @currentScope[@loopOpen.tag]!='object' then throw '{#'+@loopOpen.tag+"}should be an object (it is a #{typeof @currentScope[@loopOpen.tag]})"
			newContent= "";
			for scope,i in @currentScope[@loopOpen.tag]
				subfile= new XmlTemplater A, scope, @intelligentTagging
				subfile.applyTemplateVars()
				newContent+=subfile.content #@applyTemplateVars A,scope
				if ((subfile.getFullText().indexOf '{')!=-1) then throw "they shouln't be a { in replaced file: #{subfile.getFullText()} (1)"
			@content=@content.replace B, newContent
		else @content= @content.replace B, ""

		nextFile= new XmlTemplater @content,@currentScope,@intelligentTagging
		nextFile.applyTemplateVars()
		if ((nextFile.getFullText().indexOf '{')!=-1) then throw "they shouln't be a { in replaced file: #{nextFile.getFullText()} (3)"
		@content=nextFile.content
		return this

	dashLoop: (elementDashLoop) ->

		{B,startB,endB}= @calcB()
		# endB= @matches[@loopClose.end.i].offset+@matches[@loopClose.end.i][1].length+@charactersAdded[@loopClose.end.i]+@loopClose.end.j+1
		resultFullScope = (@calcInnerTextScope @content, startB, endB, elementDashLoop)
		for t in [0..@matches.length]
			@charactersAdded[t]-=resultFullScope.startTag
		B= resultFullScope.text
		if (@content.indexOf B)==-1 then throw "couln't find B in @content"
		A = B
		copyA= A
		
		#for deleting the opening tag
		@bracketEnd= {"i":@loopOpen.end.i,"j":@loopOpen.end.j}
		@bracketStart= {"i":@loopOpen.start.i,"j":@loopOpen.start.j}
		A= @replaceCurly("",A)
		if copyA==A then throw "A should have changed after deleting the opening tag"
		copyA= A

		#for deleting the closing tag
		@bracketEnd= {"i":@loopClose.end.i,"j":@loopClose.end.j}
		@bracketStart= {"i":@loopClose.start.i,"j":@loopClose.start.j}
		A= @replaceCurly("",A)

		if copyA==A then throw "A should have changed after deleting the opening tag"
		
		if @currentScope[@loopOpen.tag]?
			if typeof @currentScope[@loopOpen.tag]!='object' then throw '{#'+@loopOpen.tag+"}should be an object (it is a #{typeof @currentScope[@loopOpen.tag]})"
			newContent= "";
			for scope,i in @currentScope[@loopOpen.tag]
				subfile= new XmlTemplater A, scope, @intelligentTagging
				subfile.applyTemplateVars()
				newContent+=subfile.content #@applyTemplateVars A,scope
				if ((subfile.getFullText().indexOf '{')!=-1) then throw "they shouln't be a { in replaced file: #{subfile.getFullText()} (5)"
			@content= @content.replace B, newContent
		else @content= @content.replace B, ""

		nextFile= new XmlTemplater @content, @currentScope, @intelligentTagging
		nextFile.applyTemplateVars()
		@content=nextFile.content
		if ((nextFile.getFullText().indexOf '{')!=-1) then throw "they shouln't be a { in replaced file: #{nextFile.getFullText()} (6)"
		return this
	
	replaceXmlTag: (content,tagNumber,insideValue,spacePreserve=false,noStartTag=false) ->
		@matches[tagNumber][2]=insideValue #so that the matches are still correct
		startTag= @matches[tagNumber].offset+@charactersAdded[tagNumber]  #where the open tag starts: <w:t>
		#calculate the replacer according to the params
		if noStartTag == true
			replacer= insideValue
		else
			if spacePreserve==true 
				replacer= '<w:t xml:space="preserve">'+insideValue+"</w:t>"
			else replacer= @matches[tagNumber][1]+insideValue+"</w:t>"
		@charactersAdded[tagNumber+1]+=replacer.length-@matches[tagNumber][0].length
		if content.indexOf(@matches[tagNumber][0])==-1 then throw "content #{@matches[tagNumber][0]} not found in content"
		copyContent= content
		content = content.replaceFirstFrom @matches[tagNumber][0], replacer, startTag
		@matches[tagNumber][0]=replacer

		if copyContent==content then throw "offset problem0: didnt changed the value (should have changed from #{@matches[@bracketStart.i][0]} to #{replacer}"
		content		                                                                     

	replaceCurly: (newValue,content=@content) ->
		if (@matches[@bracketEnd.i][2].indexOf ('}'))==-1 then throw "no closing bracket at @bracketEnd.i #{@matches[@bracketEnd.i][2]}"
		if (@matches[@bracketStart.i][2].indexOf ('{'))==-1 then throw "no opening bracket at @bracketStart.i #{@matches[@bracketStart.i][2]}"

		if @bracketEnd.i==@bracketStart.i #<w>{aaaaa}</w>
			insideValue =@matches[@bracketStart.i][2].replace "{#{@textInsideBracket}}", newValue
			content= @replaceXmlTag(content,@bracketStart.i,insideValue,true)
		else if @bracketEnd.i>@bracketStart.i

			# 1. for the first (@bracketStart.i): replace __{.. by __value
			regexRight= /^([^{]*){.*$/
			subMatches= @matches[@bracketStart.i][2].match regexRight

			if @matches[@bracketStart.i][1]=="" #if the content starts with:  {tag</w:t>
				content= @replaceXmlTag(content,@bracketStart.i,newValue,true,true)
			else
				insideValue=subMatches[1]+newValue
				content= @replaceXmlTag(content,@bracketStart.i,insideValue,true)

			#2. for in between (@bracketStart.i+1...@bracketEnd.i) replace whole by ""
			for k in [(@bracketStart.i+1)...@bracketEnd.i]
				@charactersAdded[k+1]=@charactersAdded[k]
				content= @replaceXmlTag(content,k,"")

			#3. for the last (@bracketEnd.i) replace ..}__ by ".." ###
			regexLeft= /^[^}]*}(.*)$/;
			insideValue = @matches[@bracketEnd.i][2].replace regexLeft, '$1'
			@charactersAdded[@bracketEnd.i+1]=@charactersAdded[@bracketEnd.i]
			content= @replaceXmlTag(content,k, insideValue,true)

		else
			throw "Bracket closed before opening"

		for match, j in @matches when j>@bracketEnd.i
			@charactersAdded[j+1]=@charactersAdded[j]

		return content
	###
	content is the whole content to be tagged
	scope is the current scope
	returns the new content of the tagged content###
	applyTemplateVars:()->
		@charactersAdded=@charactersAdded
		@currentScope= @currentScope
		@inForLoop= false # bracket with sharp: {#forLoop}______{/forLoop}
		@inBracket= false # all brackets  {___}
		@inDashLoop = false	# bracket with dash: {-w:tr dashLoop} {/dashLoop}
		@textInsideBracket= ""

		for match,i in @matches
			innerText= match[2] || "" #text inside the <w:t>
			for t in [i...@matches.length]
				@charactersAdded[t+1]=@charactersAdded[t]
			for character,j in innerText
				for m,t in @matches when t<=i
					if @content[m.offset+@charactersAdded[t]]!=m[0][0] then throw "no < at the beginning of #{m[0][0]} (2)"
				if character=='{'
					if @inBracket is true then throw "Bracket already open with text: #{@textInsideBracket}"
					@inBracket= true
					@textInsideBracket= ""
					startiMatch= i
					startjMatch= j
					@bracketStart={"i":i,"j":j}

				else if character == '}'
					@bracketEnd={"i":i,"j":j}

					if @textInsideBracket[0]=='#' and @inForLoop is false and @inDashLoop is false
						tagForLoop= @textInsideBracket.substr 1
						@inForLoop= true #begin for loop
						openiStartLoop= startiMatch # open: for "{#tag}" iStart=iEnd, jStart=0, jEnd=5
						openjStartLoop= startjMatch
						openjEndLoop= j
						openiEndLoop= i
						@loopOpen={'start':@bracketStart,'end':@bracketEnd,'tag':@textInsideBracket.substr 1}
					if @textInsideBracket[0]=='-' and @inForLoop is false and @inDashLoop is false
						# tagDashLoop= @textInsideBracket.substr 1
						@inDashLoop= true
						openiStartLoop= startiMatch
						openjStartLoop= startjMatch
						openjEndLoop = j
						openiEndLoop= i
						
						regex= /^-([a-zA-Z_:]+) ([a-zA-Z_:]+)$/
						elementDashLoop= @textInsideBracket.replace regex, '$1'
						tagDashLoop= @textInsideBracket.replace regex, '$2'
						@loopOpen={'start':@bracketStart,'end':@bracketEnd,'tag':(@textInsideBracket.replace regex, '$2'),'element':(@textInsideBracket.replace regex, '$1')}

					if @inBracket is false then throw "Bracket already closed"
					@inBracket= false

					if @inForLoop is false and @inDashLoop is false
						@content = @replaceCurly(@getValueFromTag(@textInsideBracket,@currentScope))

					if @textInsideBracket[0]=='/'
						@loopClose={'start':@bracketStart,'end':@bracketEnd}
						closejStartLoop= startjMatch
						closejEndLoop= j
						
					if @textInsideBracket[0]=='/' and ('/'+tagDashLoop == @textInsideBracket) and @inDashLoop is true
						return @dashLoop(@loopOpen.element)

					if @textInsideBracket[0]=='/' and ('/'+tagForLoop == @textInsideBracket) and @inForLoop is true
						#You DashLoop= take the outer scope only if you are in a table
						dashLooping= no
						if @intelligentTagging==on
							scopeContent= @calcScopeText @content, @matches[openiStartLoop].offset+@charactersAdded[openiStartLoop],@matches[i].offset+@charactersAdded[i]-(@matches[openiStartLoop].offset+@charactersAdded[openiStartLoop])
							for t in scopeContent
								if t.tag=='<w:tc>'
									dashLooping= yes
									elementDashLoop= 'w:tr'

						if dashLooping==no
							return @forLoop(@content,@currentScope,@loopOpen.tag,@charactersAdded,@loopClose.start.i,@loopClose.end.i,@matches,@loopOpen.start.i,@loopOpen.start.j,@loopClose.end.j,@loopOpen.end.i,@loopOpen.end.j,@loopClose.start.j)
						else
							return @dashLoop(elementDashLoop)
				else #if character != '{' and character != '}'
					if @inBracket is true then @textInsideBracket+=character
		if ((@getFullText().indexOf '{')!=-1) then throw "they shouln't be a { in replaced file: #{@getFullText()} (2)"
		this