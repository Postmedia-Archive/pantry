pantry = require '../src/pantry'

test = ->
	pantry.get {
		uri: 'http://app.canada.com/southparc/query.svc/content/5095700?format=json'
	}, (item) ->
		console.log "\t#{item.Title}"
		setTimeout(test, 2000)

test()
