vows = require 'vows'
assert = require 'assert'
storage = require '../src/pantry-memory'

mockCount = 0

class MockItem
	constructor: (@state) ->
		@options = {key: "#ID-#{mockCount++}"}
		
	hasExpired: ->
		@state is 'spoiled' or @state is 'expired'
	
	hasSpoiled: ->
		@state is  'spoiled'

vows
	.describe('pantry-memory')
	.addBatch
		'when configuring capacity with no specified ideal':
			topic: -> storage.create {capacity: 100}

			'the ideal capicity will be 90%': (topic) ->
				assert.equal topic.config.ideal, 90

		'when configuring an ideal > 90%':
			topic: -> storage.create {capacity: 100, ideal: 95}

			'the ideal capicity will be 90%': (topic) ->
				assert.equal topic.config.ideal, 90

		'when configuring an ideal < 10%':
			topic: -> storage.create {capacity: 100, ideal: 5}

			'the ideal capicity will be 10%': (topic) ->
				assert.equal topic.config.ideal, 10
				
		'when configuring an ideal between 50% and 90%':
			topic: -> storage.create {capacity: 100, ideal: 75}

			'the ideal capicity will as specified': (topic) ->
				assert.equal topic.config.ideal, 75

	.addBatch
		'when capacity has been exceeded with fresh items':
			topic: ->
				storage.create({capacity: 3, ideal: 2})
					.put(new MockItem())
					.put(new MockItem())
					.put(new MockItem())
					.put(new MockItem())
			
			'cleanup will bring items stored down to the ideal': (topic) ->
				assert.equal topic.stockCount, 2

	.addBatch
		'when capacity has been exceeded and contains spoiled items':
			topic: ->
				storage.create({capacity: 5, ideal: 4})
					.put(new MockItem())
					.put(new MockItem('expired'))
					.put(new MockItem('spoiled'))
					.put(new MockItem('spoiled'))
					.put(new MockItem('spoiled'))
					.put(new MockItem())

			'cleanup will bring stock down to below the ideal': (topic) ->
				assert.equal topic.stockCount, 3
				
			'cleanup will remove all spoiled items': (topic) ->
				for k, v in topic.currentStock
					assert.ok not v.hasSpoiled()

			'the two fresh items will not have been purged': (topic) ->
				fresh = 0
				fresh++ for k, v of topic.currentStock when not v.hasExpired()
				assert.equal fresh, 2

			'the one expired ites will not have been purged': (topic) ->
				expired = 0
				expired++ for k, v of topic.currentStock when v.hasExpired() and not v.hasSpoiled()
				assert.equal expired, 1
				
	.addBatch
		'when capacity has been exceeded and contains expired items':
			topic: ->
				storage.create({capacity: 5, ideal: 4})
					.put(new MockItem())
					.put(new MockItem('expired'))
					.put(new MockItem('expired'))
					.put(new MockItem('expired'))
					.put(new MockItem('expired'))
					.put(new MockItem())

			'cleanup will bring stock down to the ideal': (topic) ->
				assert.equal topic.stockCount, 4

			'the two fresh items will not have been purged': (topic) ->
				fresh = 0
				fresh++ for k, v of topic.currentStock when not v.hasExpired()
				assert.equal fresh, 2
				
	.export(module) 
