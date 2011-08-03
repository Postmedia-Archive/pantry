pantry = require '../src/pantry'

pantry.configure { shelfLife: 5, verbosity: 'DEBUG' }

pantry.fetch { uri: 'http://app.canada.com/southparc/query.svc/content/5095700?format=xml'}, (error, results) ->
	console.log "I have a response"
	if error?
		console.log error
	else	
		console.log results.Title
