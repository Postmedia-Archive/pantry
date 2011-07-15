pantry = require '../src/pantry'

pantry.getMulti {
	uri: 'http://app.canada.com/southparc/query.svc/content/5095700?format=json'
}, 	{
	uri: 'http://app.canada.com/southparc/query.svc/relatedcontent/5095700?format=json'
}, (err, results) ->
	console.log "\tAll Done"
	#console.log "\t#{results[0].Title}"
	console.log results[0]
	
