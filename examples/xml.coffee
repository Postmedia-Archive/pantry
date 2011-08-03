pantry = require '../src/pantry'

test = ->
	pantry.fetch {
		uri: 'http://search.twitter.com/search.atom?q=winning'
	}, (error, item) ->
		console.log "\t#{item.entry[0].title}"
		setTimeout(test, 1000)

pantry.configure { shelfLife: 5 , verbosity: 'DEBUG'}
test()
