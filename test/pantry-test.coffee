should = require 'should'
pantry = require '../src/pantry'
Log = require 'coloured-log'

describe 'pantry', ->
	describe 'configure', ->
		it 'should have default configuration', ->
			config = pantry.configure {}
			config.should.have.property 'shelfLife', 60
			config.should.have.property 'maxLife', 300
			config.should.have.property 'caseSensitive', true
			config.should.have.property 'verbosity', Log.Notice
			
		it 'should allow configuration overides', ->
			config = pantry.configure { caseSensitive: false, verbosity: Log.CRITICAL}
			config.should.have.property 'shelfLife', 60
			config.should.have.property 'maxLife', 300
			config.should.have.property 'caseSensitive', false
			config.should.have.property 'verbosity', Log.CRITICAL
			
	describe 'generateKey', ->
		it 'should leave case alone if caseSensitive', ->
			key = pantry.generateKey { uri: 'http://search.twitter.com/Search.json?Q=sugar', caseSensitive: true }
			key.should.equal 'http://search.twitter.com/Search.json?Q=sugar'
		
		it 'should lower case alone if not caseSensitive', ->
			key = pantry.generateKey { uri: 'http://search.twitter.com/Search.json?Q=sugar', caseSensitive: false }
			key.should.equal 'http://search.twitter.com/search.json?q=sugar'
			
		it 'should rearrange parmaters alphabetically', ->
			key = pantry.generateKey { uri: 'http://search.twitter.com/search.json?since=1234&q=sugar', caseSensitive: true }
			key.should.equal 'http://search.twitter.com/search.json?q=sugar&since=1234'
			
	describe 'hasSpoiled', ->
		it 'should identify empty resources as spoiled', ->
			resource = {}
			pantry.hasSpoiled(resource).should.be.true
			
		it 'should identify old resources as spoiled', ->
			resource = {results: 'test', spoilsOn: new Date()}
			resource.spoilsOn.setHours resource.spoilsOn.getHours() - 1
			pantry.hasSpoiled(resource).should.be.true
				
		it 'should identify stale resources as good', ->
			resource = {results: 'test', spoilsOn: new Date()}
			resource.spoilsOn.setHours resource.spoilsOn.getHours() + 1
			pantry.hasSpoiled(resource).should.be.false

	describe 'hasExpired', ->
		it 'should identify empty resources as expired', ->
			resource = {}
			pantry.hasExpired(resource).should.be.true

		it 'should identify spoiled resources as expired', ->
			resource = {results: 'test', spoilsOn: new Date()}
			resource.spoilsOn.setHours resource.spoilsOn.getHours() - 1
			pantry.hasExpired(resource).should.be.true

		it 'should identify expired but not spoiled resources as expired', ->
			resource = {results: 'test', spoilsOn: new Date(), bestBefore: new Date()}
			resource.spoilsOn.setHours resource.spoilsOn.getHours() + 1
			resource.bestBefore.setHours resource.bestBefore.getHours() - 1
			pantry.hasExpired(resource).should.be.true
			
		it 'should identify fresh resources as good', ->
			resource = {results: 'test', spoilsOn: new Date(), bestBefore: new Date()}
			resource.spoilsOn.setHours resource.spoilsOn.getHours() + 2
			resource.bestBefore.setHours resource.bestBefore.getHours() + 1
			pantry.hasExpired(resource).should.be.false
			
	describe 'fetch', ->
		it 'should return a JSON resource as an object',  (done) ->
			@timeout 1000
			pantry.fetch 'http://search.twitter.com/search.json?q=sugar', (error, results) ->
				results.should.be.a 'object'
				done(error)
		
		it 'should return an XML resource as an object',  (done) ->
			pantry.fetch 'http://search.twitter.com/search.atom?q=sugar', (error, results) ->
				results.should.be.a 'object'
				done(error)
	
		it 'should return an error for non JSON/XML resources', (done) ->
			pantry.fetch 'http://twitter.com', (error, results) ->
				should.exist error
				done()

		it 'should return an error for non existent resources', (done) ->
			pantry.fetch 'http://search.twitter.com/bad', (error, results) ->
				should.exist error
				done()

		it 'should return an error for non existent server', (done) ->
			pantry.fetch 'http://bad.twitter.com/search.atom?q=sugar', (error, results) ->
				should.exist error
				done()

		it 'should return an error for malformed uri', (done) ->
			pantry.fetch 'bad://search.twitter.com/search.atom?q=sugar', (error, results) ->
				should.exist error
				done()
					
	describe 'storage', ->
		it 'should cache a previously requested resource', (done) ->
			pantry.storage.get 'http://search.twitter.com/search.json?q=sugar', (error, resource) ->
				should.exist resource
				resource.should.have.property 'options'
				resource.should.have.property 'results'
				
				resource.should.have.property('firstPurchased').with.instanceof(Date)
				resource.should.have.property('lastPurchased').with.instanceof(Date)
				resource.should.have.property('bestBefore').with.instanceof(Date)
				resource.should.have.property('spoilsOn').with.instanceof(Date)
				
				resource.options.should.have.property 'key'
				resource.options.should.have.property 'uri'
				resource.options.should.have.property 'shelfLife'
				resource.options.should.have.property 'maxLife'
				
				done(error)

		it 'should return cached results for subsequent calls', (done) ->
			pantry.storage.get 'http://search.twitter.com/search.json?q=sugar', (first_error, resource) ->
				should.exist resource
				pantry.fetch 'http://search.twitter.com/search.json?q=sugar', (second_error, second_results) =>
					second_results.should.eql resource.results
					done(first_error or second_error)

