should = require 'should'

Storage = require '../src/pantry-redis'
MockResource = require '../mocks/resource-mock'

describe 'pantry-redis', ->
	describe 'create', ->
		describe 'when creating a new storage object', ->
			it 'should callback with valid storage when ready', (done) ->
				new Storage {}, (err, storage) ->
					storage.should.be.an.instanceof Storage
					done err
					
	describe 'get/put', ->
		describe 'when adding an item to storage', ->
			storage = new Storage
			resource = new MockResource 'fresh', "Hello World #{new Date()}"
			it 'should not return an error', (done) ->
				storage.put resource, (err, results) ->
					done err
			it 'should be retrievable', (done) ->
				storage.get resource.options.key, (err, item) ->
					item.options.should.have.property 'key', resource.options.key
					item.should.have.property 'results', resource.results
					done err