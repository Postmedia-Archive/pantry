
vows = require 'vows'
assert = require 'assert'
pantry = require '../src/pantry'
	
vows
	.describe('pantry')
	.addBatch
		'when fetching a resource':
			topic: ->
				pantry.fetch 'http://search.twitter.com/search.json?q=sugar', @callback
				return
			
			'an object should be returned': (error, results) ->
				assert.ifError error
				assert.isObject results
				
	.export(module)
