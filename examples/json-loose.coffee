pantry = require '../src/pantry'

pantry.fetch {
	parser: 'json'
	uri: 'http://app.canada.com/entertainment/tribune.svc/ProgramDetails?programid=MV003438830000'
}, (error, item) ->
	console.log "\t#{item.titles[0]}"

