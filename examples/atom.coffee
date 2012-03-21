pantry = require '../src/pantry'
util = require 'util'

pantry.fetch {
	xmlOptions: {explicitCharkey: true, explicitArray: true}
	uri: 'http://www.edmontonjournal.com/1419033.atom'
}, (error, item) ->
	console.log util.inspect(item, false, null)