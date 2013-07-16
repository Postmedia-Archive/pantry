
process.env.NODE_ENV = 'test';

var should = require('should')
  , Storage = require('../lib/pantry-memcached')
  , MockResource = require('../mocks/resource-mock')
  , verbosity = 'silly';

describe('pantry-memcached', function() {
  return describe('get/put', function() {
    return describe('when adding an item to storage', function() {
      var resource, storage;

      storage = new Storage(null, null, verbosity);
      resource = new MockResource('fresh', "Hello World " + (new Date()));
      it('should not return an error', function(done) {
        return storage.put(resource, function(err, results) {
          return done(err);
        });
      });
      return it('should be retrievable', function(done) {
        return storage.get(resource.options.key, function(err, item) {
          item.options.should.have.property('key', resource.options.key);
          item.should.have.property('results', resource.results);
          return done(err);
        });
      });
    });
  });
});