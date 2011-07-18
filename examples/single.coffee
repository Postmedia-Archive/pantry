pantry = require '../src/pantry'


test = ->
	pantry.fetch {
		uri: 'http://search.twitter.com/search.json?q=winning'
	}, (error, item) ->
		console.log "\t#{item.results[0].text}"
		setTimeout(test, 1000)

pantry.configure { shelfLife: 5 }
test()
