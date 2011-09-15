pantry = require '../src/pantry'
util = require 'util'

pantry.fetch {
	xmlOptions: {explicitCharkey: true, explicitArray: true}
	uri: 'http://rss.cbc.ca/lineup/topstories.xml'
}, (error, item) ->
	console.log util.inspect(item, false, null)