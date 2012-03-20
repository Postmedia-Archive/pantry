should = require 'should'

Storage = require '../src/pantry-memory'
MockResource = require '../mocks/resource-mock'

countState = (storage, state) ->
	count = 0
	count++ for k, v of storage.currentStock when v.state == state
	return count

describe 'pantry-memory', ->
	describe 'create', ->
		describe 'when creating a new storage object', ->
			it 'should callback with valid storage when ready', (done) ->
				new Storage {}, (err, storage) ->
					storage.should.be.an.instanceof Storage
					done err
					
	# remaining tests do not wait for callback as memory storage is always ready once created
	
	describe 'config', ->
		describe 'when configuring capacity with no specified ideal', ->
			it 'should have an ideal capicity of 90%', ->
				(new Storage {capacity: 100}).config.should.have.property 'ideal', 90
				
		describe 'when configuring an ideal > 90%', ->
			it 'should have an ideal capicity of 90%', ->
				(new Storage {capacity: 100, ideal: 95}).config.should.have.property 'ideal', 90
		
		describe 'when configuring an ideal < 10%', ->
			it 'should have an ideal capicity of 10%', ->
				(new Storage {capacity: 100, ideal: 5}).config.should.have.property 'ideal', 10
		
		describe 'when configuring an ideal between 10% and 90%', ->
			it 'should have an ideal capicity as specified', ->
				(new Storage {capacity: 100, ideal: 11}).config.should.have.property 'ideal', 11
				(new Storage {capacity: 100, ideal: 50}).config.should.have.property 'ideal', 50
				(new Storage {capacity: 100, ideal: 89}).config.should.have.property 'ideal', 89
				
	describe 'get/put', ->
		describe 'when adding an item to storage', ->
			storage = new Storage
			resource = new MockResource 'fresh',  "Hello World #{new Date()}"
			it 'should not return an error', (done) ->
				storage.put resource, (err, results) ->
					done err
			it 'should be retrievable', (done) ->
				storage.get resource.options.key, (err, item) ->
					item.should.eql resource
					done err
	
	describe 'cleanup', ->
		describe 'when capacity has been exceeded with fresh items', ->
			storage = new Storage({capacity: 3, ideal: 2})
				.put(new MockResource())
				.put(new MockResource())
				.put(new MockResource())
				.put(new MockResource())
			it 'should bring items down to the ideal', ->
				storage.stockCount.should.equal storage.config.ideal
				
		describe 'when capacity has been exceeded and contains spoiled items', ->
			storage = new Storage({capacity: 5, ideal: 4})
				.put(new MockResource())
				.put(new MockResource('expired'))
				.put(new MockResource('spoiled'))
				.put(new MockResource('spoiled'))
				.put(new MockResource('spoiled'))
				.put(new MockResource())
			it 'should bring items below ideal', ->
				storage.stockCount.should.be.below  storage.config.ideal
			it 'should remove all spoiled items', ->
				countState(storage, 'spoiled').should.equal 0
			it 'should still contain the two fresh items', ->
				countState(storage, 'fresh').should.equal 2
			it 'should still contain the one expired item', ->
				countState(storage, 'expired').should.equal 1
				
		describe 'when capacity has been exceeded and contains expired items', ->
			storage = new Storage({capacity: 5, ideal: 4})
				.put(new MockResource())
				.put(new MockResource('expired'))
				.put(new MockResource('expired'))
				.put(new MockResource('expired'))
				.put(new MockResource('expired'))
				.put(new MockResource())
			it 'should bring items down to the ideal', ->
				storage.stockCount.should.equal storage.config.ideal
			it 'should still contain the two fresh items', ->
				countState(storage, 'fresh').should.equal 2
				
	describe 'clear', ->
		it 'should empty the storage', ->
			storage = new Storage()
				.put(new MockResource())
				.put(new MockResource())
			storage.clear()
			storage.currentStock.should.eql {}
			storage.stockCount.should.equal 0