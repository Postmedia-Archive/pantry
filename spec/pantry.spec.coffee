pantry = require('pantry')
storage = require('pantry-memory')

assert = require('assert')

module.exports =
	"Configure and verify the shelflife": ->
		config = pantry.configure { shelfLife: 5, verbosity: 'DEBUG' }
		assert.equal config.shelfLife, 5, "Expected shelflife to equal 5, it was #{config.shelfLife}"
	
	"Verify ideal is below or equal to 90% of capactiy": ->
		config = storage.configure { capacity:100, ideal:100 }
		assert.equal config.ideal, 90, "Expected ideal to be 90% of capacity, we got back #{config.ideal}"

	"Verify we can fetch a resource": ->
		pantry.fetch { uri: 'http://search.twitter.com/search.json?q=sugar' }, (error, item) ->
			assert.ok (item.results.length > 0 ),  "Expected results, result was #{item.results.length}"
			
	"Verify we have two items in stock after two unique requests": ->
		pantry.fetch { uri: 'http://search.twitter.com/search.json?q=sugar' }, (error, item) ->
			pantry.fetch { uri: 'http://search.twitter.com/search.json?q=spice'}, (error, item) ->
				pantry.getStock (error, stock) ->
					assert.equal stock.stockCount, 2,  "Stock count was expected to be 2, we have #{stock.stockCount}"
	
	"Verify capacity is never exceeded, deep chaining into callbacks to force a syncronous call of these methods": ->
		config = pantry.configure { shelflife: 10, capacity: 3, ideal: 2}
		fetchesCalled = 0
		pantry.fetch { uri: 'http://search.twitter.com/search.json?q=sugar' }, (error, item) ->
			fetchesCalled++
			pantry.fetch { uri: 'http://search.twitter.com/search.json?q=spice' }, (error, item) ->
				fetchesCalled++
				pantry.fetch { uri: 'http://search.twitter.com/search.json?q=flour' }, (error, item) ->
					fetchesCalled++
					## Check the stockcount
					pantry.getStock (error, stock) ->
						assert.equal stock.stockCount, 3 , "After third request, stock count was expected to be 3, it was #{stock.stockCount}"
	
					pantry.fetch { uri: 'http://search.twitter.com/search.json?q=salt' }, (error, item) ->
						fetchesCalled++
						## Check the stockcount
						pantry.getStock (error, stock) ->
							assert.equal stock.stockCount, 2, "On fourth request we expected stock count to be 2 which is the configured ideal value, it was #{stock.stockCount}"
						
							pantry.fetch { uri: 'http://search.twitter.com/search.json?q=cornmeal' }, (error, item) ->
								fetchesCalled++
								## Check the stockcount one last time
								pantry.getStock (error, stock) ->
									assert.equal stock.stockCount, 3, "After fifth request we expect a stock count of 3, it was #{stock.stockCount}"
									assert.equal 5, fetchesCalled, "We expected the pantry.fetch method to be called 5 times, actually called #{fetchesCalled}"
									
									## Restart
									config = pantry.configure { shelfLife: 1, maxLife: 2, capacity: 2, ideal: 1}
									pantry.fetch { uri: 'http://search.twitter.com/search.json?q=moon' }, (error, item) ->
										## Delay next requests for 1.1 seconds
										setTimeout (->	
											pantry.fetch { uri: 'http://search.twitter.com/search.json?q=stars' }, (error, item) ->
												pantry.fetch { uri: 'http://search.twitter.com/search.json?q=planets' }, (error, item) ->
													assert.isUndefined stock.currentStock['http://search.twitter.com/search.json?q=moon'], "Expected the oldest key to have been removed during cleanup, it actually returned #{stock.currentStock['http://search.twitter.com/search.json?q=moon']}."
											), 1100 #Pushes request past the first requests expiry to ensure it is targeted for cleanup