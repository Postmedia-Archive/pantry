pantry = require '../src/pantry'

pantry.fetch {
	parser: 'xml'
	uri: 'http://app.canada.com/entertainment/tribune.svc/ProgramDetails?programid=MV003438830000'
}, (error, item) ->
	console.log "\ttitle: #{item.titles[0].title[0]['#']}"

