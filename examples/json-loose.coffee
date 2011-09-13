pantry = require '../src/pantry'

pantry.fetch {
	parser: 'json'
	uri: 'http://jsonproxy.appspot.com/proxy?url=http%3A%2F%2Fapp.canada.com%2Fentertainment%2Ftribune.svc%2FProgramDetails%3Fprogramid%3DMV003438830000'
}, (error, item) ->
	console.log "\ttitle: #{item.program.titles.title['$']}"

