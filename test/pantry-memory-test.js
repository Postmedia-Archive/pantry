
var should = require('should')
  , Storage = require('../lib/pantry-memory')
  , MockResource = require('../mocks/resource-mock');

var Log = require('coloured-log');

countState = function(storage, state) {
  var count, k, v, _ref;

  count = 0;
  _ref = storage.currentStock;
  for (k in _ref) {
    v = _ref[k];
    if (v.state === state) {
      count++;
    }
  }
  return count;
};

describe('pantry-memory', function() {
  describe('config', function() {
    describe('when configuring capacity with no specified ideal', function() {
      return it('should have an ideal capicity of 90%', function() {
        return (new Storage({
          capacity: 100
        }, Log.CRITICAL)).config.should.have.property('ideal', 90);
      });
    });
    describe('when configuring an ideal > 90%', function() {
      return it('should have an ideal capicity of 90%', function() {
        return (new Storage({
          capacity: 100,
          ideal: 95
        }, Log.CRITICAL)).config.should.have.property('ideal', 90);
      });
    });
    describe('when configuring an ideal < 10%', function() {
      return it('should have an ideal capicity of 10%', function() {
        return (new Storage({
          capacity: 100,
          ideal: 5
        }, Log.CRITICAL)).config.should.have.property('ideal', 10);
      });
    });
    return describe('when configuring an ideal between 10% and 90%', function() {
      return it('should have an ideal capicity as specified', function() {
        (new Storage({
          capacity: 100,
          ideal: 11
        }, Log.CRITICAL)).config.should.have.property('ideal', 11);
        (new Storage({
          capacity: 100,
          ideal: 50
        }, Log.CRITICAL)).config.should.have.property('ideal', 50);
        return (new Storage({
          capacity: 100,
          ideal: 89
        }, Log.CRITICAL)).config.should.have.property('ideal', 89);
      });
    });
  });
  describe('get/put', function() {
    return describe('when adding an item to storage', function() {
      var resource, storage;

      storage = new Storage({}, Log.CRITICAL);
      resource = new MockResource('fresh', "Hello World " + (new Date()));
      it('should not return an error', function(done) {
        return storage.put(resource, function(err, results) {
          return done(err);
        });
      });
      return it('should be retrievable', function(done) {
        return storage.get(resource.options.key, function(err, item) {
          item.should.eql(resource);
          return done(err);
        });
      });
    });
  });
  describe('cleanup', function() {
    describe('when capacity has been exceeded with fresh items', function() {
      var storage;

      storage = new Storage({
        capacity: 3,
        ideal: 2
      }, Log.CRITICAL).put(new MockResource()).put(new MockResource()).put(new MockResource()).put(new MockResource());
      return it('should bring items down to the ideal', function() {
        return storage.stockCount.should.equal(storage.config.ideal);
      });
    });
    describe('when capacity has been exceeded and contains spoiled items', function() {
      var storage;

      storage = new Storage({
        capacity: 5,
        ideal: 4
      }, Log.CRITICAL).put(new MockResource()).put(new MockResource('expired')).put(new MockResource('spoiled')).put(new MockResource('spoiled')).put(new MockResource('spoiled')).put(new MockResource());
      it('should bring items below ideal', function() {
        return storage.stockCount.should.be.below(storage.config.ideal);
      });
      it('should remove all spoiled items', function() {
        return countState(storage, 'spoiled').should.equal(0);
      });
      it('should still contain the two fresh items', function() {
        return countState(storage, 'fresh').should.equal(2);
      });
      return it('should still contain the one expired item', function() {
        return countState(storage, 'expired').should.equal(1);
      });
    });
    return describe('when capacity has been exceeded and contains expired items', function() {
      var storage;

      storage = new Storage({
        capacity: 5,
        ideal: 4
      }, Log.CRITICAL).put(new MockResource()).put(new MockResource('expired')).put(new MockResource('expired')).put(new MockResource('expired')).put(new MockResource('expired')).put(new MockResource());
      it('should bring items down to the ideal', function() {
        return storage.stockCount.should.equal(storage.config.ideal);
      });
      return it('should still contain the two fresh items', function() {
        return countState(storage, 'fresh').should.equal(2);
      });
    });
  });
  return describe('clear', function() {
    return it('should empty the storage', function() {
      var storage;

      storage = new Storage({}, Log.CRITICAL).put(new MockResource()).put(new MockResource());
      storage.clear();
      storage.currentStock.should.eql({});
      return storage.stockCount.should.equal(0);
    });
  });
});