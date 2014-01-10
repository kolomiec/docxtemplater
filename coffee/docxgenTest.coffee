Object.size = (obj) ->
	size=0
	log = 0
	for key of obj
		size++
	size

root= global ? window
env= if global? then 'node' else 'browser'

root.docX={}
root.docXData={}


if env=='node'
	global.http= require('http')
	global.https= require('https')
	global.fs= require('fs')
	global.vm = require('vm')
	global.DOMParser = require('xmldom').DOMParser
	global.XMLSerializer= require('xmldom').XMLSerializer
	global.PNG= require('../../libs/pngjs/png-node')
	global.url= require('url')

	["grid.js","version.js","detector.js","formatinf.js","errorlevel.js","bitmat.js","datablock.js","bmparser.js","datamask.js","rsdecoder.js","gf256poly.js","gf256.js","decoder.js","qrcode.js","findpat.js","alignpat.js","databr.js"].forEach (file) ->
		vm.runInThisContext(global.fs.readFileSync(__dirname + '/../../libs/jsqrcode/' + file), file);
	['jszip.js', 'jszip-load.js', 'jszip-deflate.js', 'jszip-inflate.js'].forEach (file) ->
		vm.runInThisContext(global.fs.readFileSync(__dirname + '/../../libs/jszip/' + file), file);
	['docxgen.js'].forEach (file) ->
		vm.runInThisContext(global.fs.readFileSync(__dirname + '/../../js/' + file), file);



DocUtils.loadDoc('imageExample.docx')
DocUtils.loadDoc('image.png',true)
DocUtils.loadDoc('bootstrap_logo.png',true)
DocUtils.loadDoc('BMW_logo.png',true)
DocUtils.loadDoc('Firefox_logo.png',true)
DocUtils.loadDoc('Volkswagen_logo.png',true)
DocUtils.loadDoc('tagExample.docx')
DocUtils.loadDoc('tagExampleExpected.docx')
DocUtils.loadDoc('tagLoopExample.docx')
DocUtils.loadDoc('tagLoopExampleImageExpected.docx')
DocUtils.loadDoc('tagProduitLoop.docx')
DocUtils.loadDoc('tagDashLoop.docx')
DocUtils.loadDoc('tagDashLoopList.docx')
DocUtils.loadDoc('tagDashLoopTable.docx')
DocUtils.loadDoc('tagIntelligentLoopTable.docx',false,true)
DocUtils.loadDoc('tagIntelligentLoopTableExpected.docx')
DocUtils.loadDoc('tagDashLoop.docx')
DocUtils.loadDoc('qrCodeExample.docx')
DocUtils.loadDoc('qrCodeExampleExpected.docx')
DocUtils.loadDoc('qrCodeTaggingExample.docx')
DocUtils.loadDoc('qrCodeTaggingExampleExpected.docx')
DocUtils.loadDoc('qrCodeTaggingLoopExample.docx')
DocUtils.loadDoc('qrCodeTaggingLoopExampleExpected.docx')
DocUtils.loadDoc('qrcodeTest.zip',true)

describe "DocxGenBasis", () ->
	it "should be defined", () ->
		expect(DocxGen).not.toBe(undefined)
	it "should construct", () ->
		a= new DocxGen()
		expect(a).not.toBe(undefined)
describe "DocxGenLoading", () ->
	describe "ajax done correctly", () ->
		it "doc and img Data should have the expected length", () ->
			expect(docXData['imageExample.docx'].length).toEqual(729580)
			expect(docXData['image.png'].length).toEqual(18062)
		it "should have the right number of files (the docx unzipped)", ()->
			docX['imageExample.docx']=new DocxGen(docXData['imageExample.docx'])
			expect(Object.size(docX['imageExample.docx'].zip.files)).toEqual(22)
	describe "basic loading", () ->
		it "should load file imageExample.docx", () ->
			expect(typeof docX['imageExample.docx']).toBe('object');
	describe "content_loading", () ->
		it "should load the right content for the footer", () ->
			fullText=(docX['imageExample.docx'].getFullText("word/footer1.xml"))
			expect(fullText.length).not.toBe(0)
			expect(fullText).toBe('{last_name}{first_name}{phone}')
		it "should load the right content for the document", () ->
			fullText=(docX['imageExample.docx'].getFullText()) #default value document.xml
			expect(fullText).toBe("")
	describe "image loading", () ->
		it "should find one image (and not more than 1)", () ->
				expect(docX['imageExample.docx'].getImageList().length).toEqual(1)
		it "should find the image named with the good name", () ->
			expect((docX['imageExample.docx'].getImageList())[0].path).toEqual('word/media/image1.jpeg')
		it "should change the image with another one", () ->
			oldImageData= docX['imageExample.docx'].zip.files['word/media/image1.jpeg'].asText()
			docX['imageExample.docx'].setImage('word/media/image1.jpeg',docXData['image.png'])
			newImageData= docX['imageExample.docx'].zip.files['word/media/image1.jpeg'].asText()
			expect(oldImageData).not.toEqual(newImageData)
			expect(docXData['image.png']).toEqual(newImageData)

describe "DocxGenTemplating", () ->
	describe "text templating", () ->
		it "should change values with template vars", () ->
			templateVars=
				"first_name":"Hipp"
				"last_name":"Edgar",
				"phone":"0652455478"
				"description":"New Website"
			docX['tagExample.docx'].setTemplateVars templateVars
			docX['tagExample.docx'].applyTemplateVars()
			expect(docX['tagExample.docx'].getFullText()).toEqual('Edgar Hipp')
			expect(docX['tagExample.docx'].getFullText("word/header1.xml")).toEqual('Edgar Hipp0652455478New Website')
			expect(docX['tagExample.docx'].getFullText("word/footer1.xml")).toEqual('EdgarHipp0652455478')
		it "should export the good file", () ->
			for i of docX['tagExample.docx'].zip.files
				#Everything but the date should be different
				expect(docX['tagExample.docx'].zip.files[i].options.date).not.toBe(docX['tagExampleExpected.docx'].zip.files[i].options.date)
				expect(docX['tagExample.docx'].zip.files[i].name).toBe(docX['tagExampleExpected.docx'].zip.files[i].name)
				expect(docX['tagExample.docx'].zip.files[i].options.base64).toBe(docX['tagExampleExpected.docx'].zip.files[i].options.base64)
				#expect(docX['tagExample.docx'].zip.files[i].options.binary).toBe(docX['tagExampleExpected.docx'].zip.files[i].options.binary)
				expect(docX['tagExample.docx'].zip.files[i].options.compression).toBe(docX['tagExampleExpected.docx'].zip.files[i].options.compression)
				expect(docX['tagExample.docx'].zip.files[i].options.dir).toBe(docX['tagExampleExpected.docx'].zip.files[i].options.dir)
				expect(docX['tagExample.docx'].zip.files[i].asText()).toBe(docX['tagExampleExpected.docx'].zip.files[i].asText())

describe "DocxGenTemplatingForLoop", () ->
	describe "textLoop templating", () ->
		it "should replace all the tags", () ->
			templateVars =
				"nom":"Hipp"
				"prenom":"Edgar"
				"telephone":"0652455478"
				"description":"New Website"
				"offre":[{"titre":"titre1","prix":"1250"},{"titre":"titre2","prix":"2000"},{"titre":"titre3","prix":"1400"}]
			docX['tagLoopExample.docx'].setTemplateVars templateVars
			docX['tagLoopExample.docx'].applyTemplateVars()
			expect(docX['tagLoopExample.docx'].getFullText()).toEqual('Votre proposition commercialePrix: 1250Titre titre1Prix: 2000Titre titre2Prix: 1400Titre titre3HippEdgar')
		it "should work with loops inside loops", () ->
			templateVars = {"products":[{"title":"Microsoft","name":"DOS","reference":"Win7","avantages":[{"title":"Everyone uses it","proof":[{"reason":"it is quite cheap"},{"reason":"it is quit simple"},{"reason":"it works on a lot of different Hardware"}]}]},{"title":"Linux","name":"Ubuntu","reference":"Ubuntu10","avantages":[{"title":"It's very powerful","proof":[{"reason":"the terminal is your friend"},{"reason":"Hello world"},{"reason":"it's free"}]}]},{"title":"Apple","name":"Mac","reference":"OSX","avantages":[{"title":"It's very easy","proof":[{"reason":"you can do a lot just with the mouse"},{"reason":"It's nicely designed"}]}]},]}
			docX['tagProduitLoop.docx'].setTemplateVars templateVars
			docX['tagProduitLoop.docx'].applyTemplateVars()
			text= docX['tagProduitLoop.docx'].getFullText()
			expectedText= "MicrosoftProduct name : DOSProduct reference : Win7Everyone uses itProof that it works nicely : It works because it is quite cheap It works because it is quit simple It works because it works on a lot of different HardwareLinuxProduct name : UbuntuProduct reference : Ubuntu10It's very powerfulProof that it works nicely : It works because the terminal is your friend It works because Hello world It works because it's freeAppleProduct name : MacProduct reference : OSXIt's very easyProof that it works nicely : It works because you can do a lot just with the mouse It works because It's nicely designed"
			expect(text.length).toEqual(expectedText.length)
			expect(text).toEqual(expectedText)
describe "scope calculation" , () ->
	xmlTemplater= new DocXTemplater()
	it "should compute the scope between 2 <w:t>" , () ->
		scope= xmlTemplater.calcScopeText """undefined</w:t></w:r></w:p><w:p w:rsidP="008A4B3C" w:rsidR="007929C1" w:rsidRDefault="007929C1" w:rsidRPr="008A4B3C"><w:pPr><w:pStyle w:val="Sous-titre"/></w:pPr><w:r w:rsidRPr="008A4B3C"><w:t xml:space="preserve">Audit réalisé le """
		expect(scope).toEqual([ { tag : '</w:t>', offset : 9 }, { tag : '</w:r>', offset : 15 }, { tag : '</w:p>', offset : 21 }, { tag : '<w:p>', offset : 27 }, { tag : '<w:r>', offset : 162 }, { tag : '<w:t>', offset : 188 } ])
	it "should compute the scope between 2 <w:t> in an Array", () ->
		scope= xmlTemplater.calcScopeText """urs</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW w:type="dxa" w:w="4140"/></w:tcPr><w:p w:rsidP="00CE524B" w:rsidR="00CE524B" w:rsidRDefault="00CE524B"><w:pPr><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:color w:val="auto"/></w:rPr></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:color w:val="auto"/></w:rPr><w:t>Sur exté"""
		expect(scope).toEqual([ { tag : '</w:t>', offset : 3 }, { tag : '</w:r>', offset : 9 }, { tag : '</w:p>', offset : 15 }, { tag : '</w:tc>', offset : 21 }, { tag : '<w:tc>', offset : 28 }, { tag : '<w:p>', offset : 83 }, { tag : '<w:r>', offset : 268 }, { tag : '<w:t>', offset : 374 } ])
	it 'should compute the scope between a w:t in an array and the other outside', () ->
		scope= xmlTemplater.calcScopeText """defined </w:t></w:r></w:p></w:tc></w:tr></w:tbl><w:p w:rsidP="00CA7135" w:rsidR="00BE3585" w:rsidRDefault="00BE3585"/><w:p w:rsidP="00CA7135" w:rsidR="00BE3585" w:rsidRDefault="00BE3585"/><w:p w:rsidP="00CA7135" w:rsidR="00137C91" w:rsidRDefault="00137C91"><w:r w:rsidRPr="00B12C70"><w:rPr><w:bCs/></w:rPr><w:t>Coût ressources """
		expect(scope).toEqual([ { tag : '</w:t>', offset : 8 }, { tag : '</w:r>', offset : 14 }, { tag : '</w:p>', offset : 20 }, { tag : '</w:tc>', offset : 26 }, { tag : '</w:tr>', offset : 33 }, { tag : '</w:tbl>', offset : 40 }, { tag : '<w:p>', offset : 188 }, { tag : '<w:r>', offset : 257 }, { tag : '<w:t>', offset : 306 } ])

describe "scope diff calculation", () ->
	xmlTemplater= new DocXTemplater()
	it "should compute the scopeDiff between 2 <w:t>" , () ->
		scope= xmlTemplater.calcScopeDifference """undefined</w:t></w:r></w:p><w:p w:rsidP="008A4B3C" w:rsidR="007929C1" w:rsidRDefault="007929C1" w:rsidRPr="008A4B3C"><w:pPr><w:pStyle w:val="Sous-titre"/></w:pPr><w:r w:rsidRPr="008A4B3C"><w:t xml:space="preserve">Audit réalisé le """
		expect(scope).toEqual([])
	it "should compute the scopeDiff between 2 <w:t> in an Array", () ->
		scope= xmlTemplater.calcScopeDifference """urs</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW w:type="dxa" w:w="4140"/></w:tcPr><w:p w:rsidP="00CE524B" w:rsidR="00CE524B" w:rsidRDefault="00CE524B"><w:pPr><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:color w:val="auto"/></w:rPr></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:color w:val="auto"/></w:rPr><w:t>Sur exté"""
		expect(scope).toEqual([])
	it 'should compute the scopeDiff between a w:t in an array and the other outside', () ->
		scope= xmlTemplater.calcScopeDifference """defined </w:t></w:r></w:p></w:tc></w:tr></w:tbl><w:p w:rsidP="00CA7135" w:rsidR="00BE3585" w:rsidRDefault="00BE3585"/><w:p w:rsidP="00CA7135" w:rsidR="00BE3585" w:rsidRDefault="00BE3585"/><w:p w:rsidP="00CA7135" w:rsidR="00137C91" w:rsidRDefault="00137C91"><w:r w:rsidRPr="00B12C70"><w:rPr><w:bCs/></w:rPr><w:t>Coût ressources """
		expect(scope).toEqual([ { tag : '</w:tc>', offset : 26 }, { tag : '</w:tr>', offset : 33 }, { tag : '</w:tbl>', offset : 40 } ])

describe "scope inner text", () ->
	it "should find the scope" , () ->
		xmlTemplater= new DocXTemplater()
		docX['tagProduitLoop.docx']= new DocxGen(docXData['tagProduitLoop.docx'])
		scope= xmlTemplater.calcInnerTextScope docX['tagProduitLoop.docx'].zip.files["word/document.xml"].asText() ,1195,1245,'w:p'
		obj= { text : """<w:p w:rsidR="00923B77" w:rsidRDefault="00923B77"><w:r><w:t>{#</w:t></w:r><w:r w:rsidR="00713414"><w:t>products</w:t></w:r><w:r><w:t>}</w:t></w:r></w:p>""", startTag : 1134, endTag : 1286 }
		expect(scope.endTag).toEqual(obj.endTag)
		expect(scope.startTag).toEqual(obj.startTag)
		expect(scope.text.length).toEqual(obj.text.length)
		expect(scope.text).toEqual(obj.text)

describe "Dash Loop Testing", () ->
	it "dash loop ok on simple table -> w:tr" , () ->
		templateVars=
			"os":[{"type":"linux","price":"0","reference":"Ubuntu10"},{"type":"DOS","price":"500","reference":"Win7"},{"type":"apple","price":"1200","reference":"MACOSX"}]
		docX['tagDashLoop.docx'].setTemplateVars(templateVars)
		docX['tagDashLoop.docx'].applyTemplateVars()
		expectedText= "linux0Ubuntu10DOS500Win7apple1200MACOSX"
		text=docX['tagDashLoop.docx'].getFullText()
		expect(text).toBe(expectedText)
	it "dash loop ok on simple table -> w:table" , () ->
		templateVars=
			"os":[{"type":"linux","price":"0","reference":"Ubuntu10"},{"type":"DOS","price":"500","reference":"Win7"},{"type":"apple","price":"1200","reference":"MACOSX"}]
		docX['tagDashLoopTable.docx'].setTemplateVars(templateVars)
		docX['tagDashLoopTable.docx'].applyTemplateVars()
		expectedText= "linux0Ubuntu10DOS500Win7apple1200MACOSX"
		text=docX['tagDashLoopTable.docx'].getFullText()
		expect(text).toBe(expectedText)
	it "dash loop ok on simple list -> w:p" , () ->
		templateVars=
			"os":[{"type":"linux","price":"0","reference":"Ubuntu10"},{"type":"DOS","price":"500","reference":"Win7"},{"type":"apple","price":"1200","reference":"MACOSX"}]
		docX['tagDashLoopList.docx'].setTemplateVars(templateVars)
		docX['tagDashLoopList.docx'].applyTemplateVars()
		expectedText= 'linux 0 Ubuntu10 DOS 500 Win7 apple 1200 MACOSX '
		text=docX['tagDashLoopList.docx'].getFullText()
		expect(text).toBe(expectedText)

describe "Intelligent Loop Tagging", () ->
	it "should work with tables" , () ->
		templateVars={clients:[{first_name:"John",last_name:"Doe",phone:"+33647874513"},{first_name:"Jane",last_name:"Doe",phone:"+33454540124"},{first_name:"Phil",last_name:"Kiel",phone:"+44578451245"},{first_name:"Dave",last_name:"Sto",phone:"+44548787984"}]}
		docX['tagIntelligentLoopTable.docx'].setTemplateVars(templateVars)
		docX['tagIntelligentLoopTable.docx'].applyTemplateVars()
		expectedText= 'JohnDoe+33647874513JaneDoe+33454540124PhilKiel+44578451245DaveSto+44548787984'
		text= docX['tagIntelligentLoopTableExpected.docx'].getFullText()
		expect(text).toBe(expectedText)
		for i of docX['tagIntelligentLoopTable.docx'].zip.files
			# Everything but the date should be different
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].asText()).toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].asText())
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].name).toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].name)
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].options.base64).toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].options.base64)
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].options.binary).toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].options.binary)
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].options.compression).toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].options.compression)
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].options.dir).toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].options.dir)
			expect(docX['tagIntelligentLoopTable.docx'].zip.files[i].options.date).not.toBe(docX['tagIntelligentLoopTableExpected.docx'].zip.files[i].options.date)

describe "getTemplateVars", () ->
	it "should work with simple document", () ->
		docX['tagExample.docx']=new DocxGen docXData['tagExample.docx'],{},false
		tempVars= docX['tagExample.docx'].getTemplateVars()
		expect(tempVars).toEqual([ { fileName : 'word/document.xml', vars : { last_name : true, first_name : true } }, { fileName : 'word/footer1.xml', vars : { last_name : true, first_name : true, phone : true } }, { fileName : 'word/header1.xml', vars : { last_name : true, first_name : true, phone : true, description : true } }])
	it "should work with loop document", () ->
		docX['tagLoopExample.docx']=new DocxGen docXData['tagLoopExample.docx'],{},false
		tempVars= docX['tagLoopExample.docx'].getTemplateVars()
		expect(tempVars).toEqual([ { fileName : 'word/document.xml', vars : { offre : { prix : true, titre : true }, nom : true, prenom : true } }, { fileName : 'word/footer1.xml', vars : { nom : true, prenom : true, telephone : true } }, { fileName : 'word/header1.xml', vars : { nom : true, prenom : true } } ])
	it 'should work if there are no templateVars', () ->
		docX['qrCodeExample.docx']=new DocxGen docXData['qrCodeExample.docx'],{},false
		tempVars= docX['qrCodeExample.docx'].getTemplateVars()
		expect(tempVars).toEqual([])



describe "xmlTemplater", ()->
	it "should work with simpleContent", ()->
		content= """<w:t>Hello {name}</w:t>"""
		scope= {"name":"Edgar"}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.getFullText()).toBe('Hello Edgar')

	it "should work with non w:t content", ()->
		content= """{image}.png"""
		scope= {"image":"edgar"}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.content).toBe('edgar.png')
	it "should work with tag in two elements", ()->
		content= """<w:t>Hello {</w:t><w:t>name}</w:t>"""
		scope= {"name":"Edgar"}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.getFullText()).toBe('Hello Edgar')
	it "should work with simple Loop", ()->
		content= """<w:t>Hello {#names}{name},{/names}</w:t>"""
		scope= {"names":[{"name":"Edgar"},{"name":"Mary"},{"name":"John"}]}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.getFullText()).toBe('Hello Edgar,Mary,John,')
	it "should work with dash Loop", ()->
		content= """<w:p><w:t>Hello {-w:p names}{name},{/names}</w:t></w:p>"""
		scope= {"names":[{"name":"Edgar"},{"name":"Mary"},{"name":"John"}]}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.getFullText()).toBe('Hello Edgar,Hello Mary,Hello John,')
	it "should work with loop and innerContent", ()->
		content= """</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRDefault="00713414" w:rsidP="00923B77"><w:pPr><w:pStyle w:val="Titre1"/></w:pPr><w:r><w:t>{title</w:t></w:r><w:r w:rsidR="00923B77"><w:t>}</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRPr="00923B77" w:rsidRDefault="00713414" w:rsidP="00923B77"><w:r><w:t>Proof that it works nicely :</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRDefault="00923B77" w:rsidP="00923B77"><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>{#pr</w:t></w:r><w:r w:rsidR="00713414"><w:t>oof</w:t></w:r><w:r><w:t xml:space="preserve">} </w:t></w:r><w:r w:rsidR="00713414"><w:t>It works because</w:t></w:r><w:r><w:t xml:space="preserve"> {</w:t></w:r><w:r w:rsidR="006F26AC"><w:t>reason</w:t></w:r><w:r><w:t>}</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRDefault="00713414" w:rsidP="00923B77"><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>{/proof</w:t></w:r><w:r w:rsidR="00923B77"><w:t>}</w:t></w:r></w:p><w:p w:rsidR="00FD04E9" w:rsidRDefault="00923B77"><w:r><w:t>"""
		scope= {"title":"Everyone uses it","proof":[{"reason":"it is quite cheap"},{"reason":"it is quit simple"},{"reason":"it works on a lot of different Hardware"}]}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.getFullText()).toBe('Everyone uses itProof that it works nicely : It works because it is quite cheap It works because it is quit simple It works because it works on a lot of different Hardware')
	it "should work with loop and innerContent (with last)", ()->
		content= """</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRDefault="00713414" w:rsidP="00923B77"><w:pPr><w:pStyle w:val="Titre1"/></w:pPr><w:r><w:t>{title</w:t></w:r><w:r w:rsidR="00923B77"><w:t>}</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRPr="00923B77" w:rsidRDefault="00713414" w:rsidP="00923B77"><w:r><w:t>Proof that it works nicely :</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRDefault="00923B77" w:rsidP="00923B77"><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>{#pr</w:t></w:r><w:r w:rsidR="00713414"><w:t>oof</w:t></w:r><w:r><w:t xml:space="preserve">} </w:t></w:r><w:r w:rsidR="00713414"><w:t>It works because</w:t></w:r><w:r><w:t xml:space="preserve"> {</w:t></w:r><w:r w:rsidR="006F26AC"><w:t>reason</w:t></w:r><w:r><w:t>}</w:t></w:r></w:p><w:p w:rsidR="00923B77" w:rsidRDefault="00713414" w:rsidP="00923B77"><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>{/proof</w:t></w:r><w:r w:rsidR="00923B77"><w:t>}</w:t></w:r></w:p><w:p w:rsidR="00FD04E9" w:rsidRDefault="00923B77"><w:r><w:t> """
		scope= {"title":"Everyone uses it","proof":[{"reason":"it is quite cheap"},{"reason":"it is quit simple"},{"reason":"it works on a lot of different Hardware"}]}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.getFullText()).toBe('Everyone uses itProof that it works nicely : It works because it is quite cheap It works because it is quit simple It works because it works on a lot of different Hardware')
	it 'should work with not w:t tag (if the for loop is like {#forloop} text {/forloop}) ', ()->
		content= """Hello {#names}{name},{/names}"""
		scope= {"names":[{"name":"Edgar"},{"name":"Mary"},{"name":"John"}]}
		xmlTemplater= new DocXTemplater(content,null,scope)
		xmlTemplater.applyTemplateVars()
		expect(xmlTemplater.content).toBe('Hello Edgar,Mary,John,')


describe 'DocxQrCode module', () ->
	describe "Calculate simple Docx", () ->
		f=null; fCalled=null;qrcodezip=null;obj=null;
		beforeEach () ->
			qrcodezip= new JSZip(docXData['qrcodeTest.zip'])
			docx= new DocxGen()
			obj= new DocXTemplater("",docx,{Tag:"tagValue"})


		it "should work with Blablalalabioeajbiojbepbroji", () ->

			runs () ->
				fCalled= false
				f= {test:() -> fCalled= true}
				spyOn(f,'test').andCallThrough()
				if env=='browser'
					qr=new DocxQrCode(qrcodezip.files['blabla.png'].asText(),obj,"custom.png",6)
					qr.decode(f.test)
				else
					base64= JSZip.base64.encode qrcodezip.files['blabla.png'].asText()
					binaryData = new Buffer(base64, 'base64') #.toString('binary');
					png= new PNG(binaryData)
					finished= (a) ->
						png.decoded= a
						qr= new DocxQrCode(png,obj,"custom.png",6)
						qr.decode(f.test)
					dat= png.decode(finished)

			waitsFor( ()->fCalled)

			runs () ->
				expect(f.test).toHaveBeenCalled();
				expect(f.test.calls.length).toEqual(1);
				expect(f.test.mostRecentCall.args[0].result).toEqual("Blablalalabioeajbiojbepbroji");
				expect(f.test.mostRecentCall.args[1]).toEqual("custom.png");
				expect(f.test.mostRecentCall.args[2]).toEqual(6);

		it "should work with long texts", () ->

			runs () ->
				fCalled= false
				f= {test:() -> fCalled= true}
				spyOn(f,'test').andCallThrough()
				if env=='browser'
					qr=new DocxQrCode(qrcodezip.files['custom.png'].asText(),obj,"custom.png",6)
					qr.decode(f.test)
				else
					base64= JSZip.base64.encode qrcodezip.files['custom.png'].asText()
					binaryData = new Buffer(base64, 'base64') #.toString('binary');
					png= new PNG(binaryData)
					finished= (a) ->
						png.decoded= a
						qr= new DocxQrCode(png,obj,"custom.png",6)
						qr.decode(f.test)
					dat= png.decode(finished)

			waitsFor( ()->fCalled)


			runs () ->
				expect(f.test).toHaveBeenCalled();
				expect(f.test.calls.length).toEqual(1);
				expect(f.test.mostRecentCall.args[0].result).toEqual("Some custom text");
				expect(f.test.mostRecentCall.args[1]).toEqual("custom.png");
				expect(f.test.mostRecentCall.args[2]).toEqual(6);


		it "should work with basic image", () ->
			runs () ->
				fCalled= false
				f= {test:() -> fCalled= true}
				spyOn(f,'test').andCallThrough()
				if env=='browser'
					qr=new DocxQrCode(qrcodezip.files['qrcodeTest.png'].asText(),obj,"qrcodeTest.png",4)
					qr.decode(f.test)
				else
					base64= JSZip.base64.encode qrcodezip.files['qrcodeTest.png'].asText()
					binaryData = new Buffer(base64, 'base64') #.toString('binary');
					png= new PNG(binaryData)
					finished= (a) ->
						png.decoded= a
						qr= new DocxQrCode(png,obj,"qrcodeTest.png",4)
						qr.decode(f.test)
					dat= png.decode(finished)

			waitsFor( ()->fCalled)

			runs () ->
				expect(f.test).toHaveBeenCalled();
				expect(f.test.calls.length).toEqual(1);
				expect(f.test.mostRecentCall.args[0].result).toEqual("test");
				expect(f.test.mostRecentCall.args[1]).toEqual("qrcodeTest.png");
				expect(f.test.mostRecentCall.args[2]).toEqual(4);

		it "should work with image with {tags}", () ->

			runs () ->
				fCalled= false
				f= {test:() -> fCalled= true}
				spyOn(f,'test').andCallThrough()
				if env=='browser'
					qr=new DocxQrCode(qrcodezip.files['qrcodetag.png'].asText(),obj,"tag.png",2)
					qr.decode(f.test)
				else
					base64= JSZip.base64.encode qrcodezip.files['qrcodetag.png'].asText()
					binaryData = new Buffer(base64, 'base64') #.toString('binary');
					png= new PNG(binaryData)
					finished= (a) ->
						png.decoded= a
						qr= new DocxQrCode(png,obj,"tag.png",2)
						qr.decode(f.test)
					dat= png.decode(finished)

			waitsFor( ()->fCalled)

			runs () ->
				expect(f.test).toHaveBeenCalled();
				expect(f.test.calls.length).toEqual(1);
				expect(f.test.mostRecentCall.args[0].result).toEqual("tagValue");
				expect(f.test.mostRecentCall.args[1]).toEqual("tag.png");
				expect(f.test.mostRecentCall.args[2]).toEqual(2);


describe "image Loop Replacing", () ->
	describe 'rels', () ->
		it 'should load', () ->
			expect(docX['imageExample.docx'].loadImageRels().imageRels).toEqual([])
			expect(docX['imageExample.docx'].maxRid).toEqual(10)
		it 'should add', () ->
			oldData= docX['imageExample.docx'].zip.files['word/_rels/document.xml.rels'].asText()
			expect(docX['imageExample.docx'].addImageRels('image1.png',docXData['bootstrap_logo.png'])).toBe(11)

			expect(docX['imageExample.docx'].zip.files['word/_rels/document.xml.rels'].asText()).not.toBe(oldData)

			relsData = docX['imageExample.docx'].zip.files['word/_rels/document.xml.rels'].asText()
			contentTypeData = docX['imageExample.docx'].zip.files['[Content_Types].xml'].asText()

			relsXml= DocUtils.Str2xml(relsData)
			contentTypeXml= DocUtils.Str2xml(contentTypeData)

			relationships= relsXml.getElementsByTagName('Relationship')
			contentTypes= contentTypeXml.getElementsByTagName('Default')

			expect(relationships.length).toEqual(11)
			expect(contentTypes.length).toBe(4)


describe "loop forTagging images", () ->
	it 'should work with a simple loop file', () ->
		docX['tagLoopExample.docx']= new DocxGen(docXData['tagLoopExample.docx'])
		tempVars=
			"nom":"Hipp"
			"prenom":"Edgar"
			"telephone":"0652455478"
			"description":"New Website"
			"offre":[
				"titre":"titre1"
				"prix":"1250"
				"img":[{data:docXData['Volkswagen_logo.png'],name:"vw_logo.png"}]
			,
				"titre":"titre2"
				"prix":"2000"
				"img":[{data:docXData['BMW_logo.png'],name:"bmw_logo.png"}]
			,
				"titre":"titre3"
				"prix":"1400"
				"img":[{data:docXData['Firefox_logo.png'],name:"firefox_logo.png"}]
			]
		docX['tagLoopExample.docx'].setTemplateVars(tempVars)
		docX['tagLoopExample.docx'].applyTemplateVars()

		for i of docX['tagLoopExample.docx'].zip.files
		# 	#Everything but the date should be different
			expect(docX['tagLoopExample.docx'].zip.files[i].options.date).not.toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].options.date)
			expect(docX['tagLoopExample.docx'].zip.files[i].name).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].name)
			expect(docX['tagLoopExample.docx'].zip.files[i].options.base64).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].options.base64)
			expect(docX['tagLoopExample.docx'].zip.files[i].options.binary).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].options.binary)
			expect(docX['tagLoopExample.docx'].zip.files[i].options.compression).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].options.compression)
			expect(docX['tagLoopExample.docx'].zip.files[i].options.dir).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].options.dir)

			if i!='word/_rels/document.xml.rels' and i!='[Content_Types].xml'
				if env=='browser' or i!="word/document.xml" #document.xml is not the same on node, so we don't test the data
					if docX['tagLoopExample.docx'].zip.files[i].asText()?0
						expect(docX['tagLoopExample.docx'].zip.files[i].asText().length).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].asText().length)
					expect(docX['tagLoopExample.docx'].zip.files[i].asText()).toBe(docX['tagLoopExampleImageExpected.docx'].zip.files[i].asText())

		relsData = docX['tagLoopExample.docx'].zip.files['word/_rels/document.xml.rels'].asText()
		contentTypeData = docX['tagLoopExample.docx'].zip.files['[Content_Types].xml'].asText()

		relsXml= DocUtils.Str2xml(relsData)
		contentTypeXml= DocUtils.Str2xml(contentTypeData)

		relationships= relsXml.getElementsByTagName('Relationship')
		contentTypes= contentTypeXml.getElementsByTagName('Default')

		expect(relationships.length).toEqual(16)
		expect(contentTypes.length).toBe(3)

describe 'qr code testing', () ->
	it 'should work with local QRCODE without tags', () ->
		docX['qrCodeExample.docx']=new DocxGen(docXData['qrCodeExample.docx'],{},false,true)
		endcallback= () -> 1
		docX['qrCodeExample.docx'].applyTemplateVars({},endcallback)

		waitsFor () -> docX['qrCodeExample.docx'].ready?

		runs () ->

			expect(docX['qrCodeExample.docx'].zip.files['word/media/Copie_0.png']?).toBeTruthy()
			for i of docX['qrCodeExample.docx'].zip.files
			# 	#Everything but the date should be different
				expect(docX['qrCodeExample.docx'].zip.files[i].options.date).not.toBe(docX['qrCodeExampleExpected.docx'].zip.files[i].options.date)
				expect(docX['qrCodeExample.docx'].zip.files[i].name).toBe(docX['qrCodeExampleExpected.docx'].zip.files[i].name)
				expect(docX['qrCodeExample.docx'].zip.files[i].options.base64).toBe(docX['qrCodeExampleExpected.docx'].zip.files[i].options.base64)
				expect(docX['qrCodeExample.docx'].zip.files[i].options.binary).toBe(docX['qrCodeExampleExpected.docx'].zip.files[i].options.binary)
				expect(docX['qrCodeExample.docx'].zip.files[i].options.compression).toBe(docX['qrCodeExampleExpected.docx'].zip.files[i].options.compression)
				expect(docX['qrCodeExample.docx'].zip.files[i].options.dir).toBe(docX['qrCodeExampleExpected.docx'].zip.files[i].options.dir)

	it 'should work with local QRCODE with {tags}', () ->
		docX['qrCodeTaggingExample.docx']=new DocxGen(docXData['qrCodeTaggingExample.docx'],{'image':'Firefox_logo'},false,true)
		endcallback= () -> 1
		docX['qrCodeTaggingExample.docx'].applyTemplateVars({'image':'Firefox_logo'},endcallback)

		waitsFor () -> docX['qrCodeTaggingExample.docx'].ready?

		runs () ->
			expect(docX['qrCodeTaggingExample.docx'].zip.files['word/media/Copie_0.png']?).toBeTruthy()
			for i of docX['qrCodeTaggingExample.docx'].zip.files
			# 	#Everything but the date should be different
				expect(docX['qrCodeTaggingExample.docx'].zip.files[i].options.date).not.toBe(docX['qrCodeTaggingExampleExpected.docx'].zip.files[i].options.date)
				expect(docX['qrCodeTaggingExample.docx'].zip.files[i].name).toBe(docX['qrCodeTaggingExampleExpected.docx'].zip.files[i].name)
				expect(docX['qrCodeTaggingExample.docx'].zip.files[i].options.base64).toBe(docX['qrCodeTaggingExampleExpected.docx'].zip.files[i].options.base64)
				expect(docX['qrCodeTaggingExample.docx'].zip.files[i].options.binary).toBe(docX['qrCodeTaggingExampleExpected.docx'].zip.files[i].options.binary)
				expect(docX['qrCodeTaggingExample.docx'].zip.files[i].options.compression).toBe(docX['qrCodeTaggingExampleExpected.docx'].zip.files[i].options.compression)
				expect(docX['qrCodeTaggingExample.docx'].zip.files[i].options.dir).toBe(docX['qrCodeTaggingExampleExpected.docx'].zip.files[i].options.dir)

	it 'should work with loop QRCODE with {tags}', () ->
		docX['qrCodeTaggingLoopExample.docx']=new DocxGen(docXData['qrCodeTaggingLoopExample.docx'],{},false,true)
		endcallback= () -> 1
		docX['qrCodeTaggingLoopExample.docx'].applyTemplateVars({'images':[{image:'Firefox_logo'},{image:'image'}]},endcallback)
		docX['qrCodeTaggingLoopExample.docx']

		waitsFor () -> docX['qrCodeTaggingLoopExample.docx'].ready?

		runs () ->

			expect(docX['qrCodeTaggingLoopExample.docx'].zip.files['word/media/Copie_0.png']?).toBeTruthy()
			expect(docX['qrCodeTaggingLoopExample.docx'].zip.files['word/media/Copie_1.png']?).toBeTruthy()
			expect(docX['qrCodeTaggingLoopExample.docx'].zip.files['word/media/Copie_2.png']?).toBeFalsy()
			# docX['qrCodeTaggingLoopExample.docx'].output()

			for i of docX['qrCodeTaggingLoopExample.docx'].zip.files
				#Everything but the date should be different
				expect(docX['qrCodeTaggingLoopExample.docx'].zip.files[i].options.date).not.toBe(docX['qrCodeTaggingLoopExampleExpected.docx'].zip.files[i].options.date)
				expect(docX['qrCodeTaggingLoopExample.docx'].zip.files[i].name).toBe(docX['qrCodeTaggingLoopExampleExpected.docx'].zip.files[i].name)
				expect(docX['qrCodeTaggingLoopExample.docx'].zip.files[i].options.base64).toBe(docX['qrCodeTaggingLoopExampleExpected.docx'].zip.files[i].options.base64)
				expect(docX['qrCodeTaggingLoopExample.docx'].zip.files[i].options.binary).toBe(docX['qrCodeTaggingLoopExampleExpected.docx'].zip.files[i].options.binary)
				expect(docX['qrCodeTaggingLoopExample.docx'].zip.files[i].options.compression).toBe(docX['qrCodeTaggingLoopExampleExpected.docx'].zip.files[i].options.compression)
				expect(docX['qrCodeTaggingLoopExample.docx'].zip.files[i].options.dir).toBe(docX['qrCodeTaggingLoopExampleExpected.docx'].zip.files[i].options.dir)
