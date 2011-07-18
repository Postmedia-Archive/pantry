pantry = require '../src/pantry'

pantry.configure { shelfLife: 5 }

pantry.fetch { uri: 'http://search.twitter.com/search.json?q=winning'}, (error, item) ->
	console.log "\t#{item.results[0].text}"
