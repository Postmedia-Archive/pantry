(function() {
  var assert, pantry;
  pantry = require('pantry');
  assert = require('assert');
  module.exports = {
    "Configure and verify the shelflife": function() {
      var config;
      config = pantry.configure({
        shelfLife: 5,
        verbosity: 'DEBUG'
      });
      return assert.equal(config.shelfLife, 5, "Expected shelflife to equal 5, it was " + config.shelfLife);
    },
    "Verify ideal is below or equal to 90% of capactiy": function() {
      var config;
      config = pantry.configure({
        capacity: 100,
        ideal: 100
      });
      return assert.equal(config.ideal, 90, "Expected ideal to be 90% of capacity, we got back " + config.ideal);
    },
    "Verify we can fetch a resource": function() {
      return pantry.fetch({
        uri: 'http://search.twitter.com/search.json?q=sugar'
      }, function(error, item) {
        return assert.ok(item.results.length > 0, "Expected results, result was " + item.results.length);
      });
    },
    "Verify we have two items in stock after two unique requests": function() {
      return pantry.fetch({
        uri: 'http://search.twitter.com/search.json?q=sugar'
      }, function(error, item) {
        return pantry.fetch({
          uri: 'http://search.twitter.com/search.json?q=spice'
        }, function(error, item) {
          return pantry.getStock(function(error, stock) {
            return assert.equal(stock.stockCount, 2, "Stock count was expected to be 2, we have " + stock.stockCount);
          });
        });
      });
    },
    "Verify capacity is never exceeded, deep chaining into callbacks to force a syncronous call of these methods": function() {
      var config, fetchesCalled;
      config = pantry.configure({
        shelflife: 10,
        capacity: 3,
        ideal: 2
      });
      fetchesCalled = 0;
      return pantry.fetch({
        uri: 'http://search.twitter.com/search.json?q=sugar'
      }, function(error, item) {
        fetchesCalled++;
        return pantry.fetch({
          uri: 'http://search.twitter.com/search.json?q=spice'
        }, function(error, item) {
          fetchesCalled++;
          return pantry.fetch({
            uri: 'http://search.twitter.com/search.json?q=flour'
          }, function(error, item) {
            fetchesCalled++;
            pantry.getStock(function(error, stock) {
              return assert.equal(stock.stockCount, 3, "After third request, stock count was expected to be 3, it was " + stock.stockCount);
            });
            return pantry.fetch({
              uri: 'http://search.twitter.com/search.json?q=salt'
            }, function(error, item) {
              fetchesCalled++;
              return pantry.getStock(function(error, stock) {
                assert.equal(stock.stockCount, 2, "On fourth request we expected stock count to be 2 which is the configured ideal value, it was " + stock.stockCount);
                return pantry.fetch({
                  uri: 'http://search.twitter.com/search.json?q=cornmeal'
                }, function(error, item) {
                  fetchesCalled++;
                  return pantry.getStock(function(error, stock) {
                    assert.equal(stock.stockCount, 3, "After fifth request we expect a stock count of 3, it was " + stock.stockCount);
                    assert.equal(5, fetchesCalled, "We expected the pantry.fetch method to be called 5 times, actually called " + fetchesCalled);
                    config = pantry.configure({
                      shelfLife: 1,
                      maxLife: 2,
                      capacity: 2,
                      ideal: 1
                    });
                    return pantry.fetch({
                      uri: 'http://search.twitter.com/search.json?q=moon'
                    }, function(error, item) {
                      return setTimeout((function() {
                        return pantry.fetch({
                          uri: 'http://search.twitter.com/search.json?q=stars'
                        }, function(error, item) {
                          return pantry.fetch({
                            uri: 'http://search.twitter.com/search.json?q=planets'
                          }, function(error, item) {
                            return assert.isUndefined(stock.currentStock['http://search.twitter.com/search.json?q=moon'], "Expected the oldest key to have been removed during cleanup, it actually returned " + stock.currentStock['http://search.twitter.com/search.json?q=moon'] + ".");
                          });
                        });
                      }), 1100);
                    });
                  });
                });
              });
            });
          });
        });
      });
    }
  };
}).call(this);
