

var should = require('should')
  , pantry = require('../lib/pantry')
  , jsonURL = 'http://api.flickr.com/services/rest/?api_key=999a559d39e8a2c23397f740d53e4447&format=json&method=flickr.test.echo&nojsoncallback=1'
  , xmlURL = 'http://api.flickr.com/services/rest/?method=flickr.test.echo&api_key=999a559d39e8a2c23397f740d53e4447&format=rest';

describe('pantry', function() {
  describe('configure', function() {
    
    it('should have default configuration', function() {
      var config;
      config = pantry.configure({});
      config.should.have.property('shelfLife', 60);
      config.should.have.property('maxLife', 300);
      config.should.have.property('caseSensitive', true);
    });
    
    it('should allow configuration overides', function() {
      var config;
      config = pantry.configure({
        caseSensitive: false
      });
      config.should.have.property('shelfLife', 60);
      config.should.have.property('maxLife', 300);
      config.should.have.property('caseSensitive', false);
    });
    
  });
  
  describe('generateKey', function() {
    
    it('should leave case alone if caseSensitive', function() {
      var key = pantry.generateKey({
        uri: 'http://search.twitter.com/Search.json?Q=sugar',
        caseSensitive: true
      });
      key.should.equal('http://search.twitter.com/Search.json?Q=sugar');
    });
    
    it('should lower case alone if not caseSensitive', function() {
      var key = pantry.generateKey({
        uri: 'http://search.twitter.com/Search.json?Q=sugar',
        caseSensitive: false
      });
      key.should.equal('http://search.twitter.com/search.json?q=sugar');
    });
    
    it('should rearrange parmaters alphabetically', function() {
      var key = pantry.generateKey({
        uri: 'http://search.twitter.com/search.json?since=1234&q=sugar',
        caseSensitive: true
      });
      key.should.equal('http://search.twitter.com/search.json?q=sugar&since=1234');
    });
    
  });
  
  describe('hasSpoiled', function() {
    
    it('should identify empty resources as spoiled', function() {
      var resource = {};
      pantry.hasSpoiled(resource).should.be.true;
    });
    
    it('should identify old resources as spoiled', function() {
      var resource = {
        results: 'test',
        spoilsOn: new Date()
      };
      resource.spoilsOn.setHours(resource.spoilsOn.getHours() - 1);
      pantry.hasSpoiled(resource).should.be.true;
    });
    
    it('should identify stale resources as good', function() {
      var resource = {
        results: 'test',
        spoilsOn: new Date()
      };
      resource.spoilsOn.setHours(resource.spoilsOn.getHours() + 1);
      pantry.hasSpoiled(resource).should.be.false;
    });
    
  });
  
  describe('hasExpired', function() {
    
    it('should identify empty resources as expired', function() {
      var resource = {};
      pantry.hasExpired(resource).should.be.true;
    });
    
    it('should identify spoiled resources as expired', function() {
      var resource = {
        results: 'test',
        spoilsOn: new Date()
      };
      
      resource.spoilsOn.setHours(resource.spoilsOn.getHours() - 1);
      pantry.hasExpired(resource).should.be.true;
    });
    
    it('should identify expired but not spoiled resources as expired', function() {
      var resource = {
        results: 'test',
        spoilsOn: new Date(),
        bestBefore: new Date()
      };
      resource.spoilsOn.setHours(resource.spoilsOn.getHours() + 1);
      resource.bestBefore.setHours(resource.bestBefore.getHours() - 1);
      pantry.hasExpired(resource).should.be.true;
    });
    
    it('should identify fresh resources as good', function() {
      var resource = {
        results: 'test',
        spoilsOn: new Date(),
        bestBefore: new Date()
      };
      resource.spoilsOn.setHours(resource.spoilsOn.getHours() + 2);
      resource.bestBefore.setHours(resource.bestBefore.getHours() + 1);
      pantry.hasExpired(resource).should.be.false;
    });
    
  });
  
  describe('fetch', function() {
    it('should return a JSON resource as an object', function(done) {
      this.timeout(1000);
      pantry.fetch(jsonURL, function(error, results) {
        results.should.be.a('object');
        done(error);
      });
    });
    
    it('should return an XML resource as an object', function(done) {
      pantry.fetch(xmlURL, function(error, results) {
        results.should.be.a('object');
        done(error);
      });
    });
    
    it('should return an error for non JSON/XML resources', function(done) {
      pantry.fetch('http://google.com', function(error, results) {
        should.exist(error);
        done();
      });
    });
    
    it('should return an error for non existent resources', function(done) {
      pantry.fetch('http://search.twitter.com/bad', function(error, results) {
        should.exist(error);
        done();
      });
    });
    
    it('should return an error for non existent server', function(done) {
      pantry.fetch('http://bad.twitter.com/search.atom?q=sugar', function(error, results) {
        should.exist(error);
        done();
      });
    });
    
    it('should return an error for malformed uri', function(done) {
      return pantry.fetch('bad://search.twitter.com/search.atom?q=sugar', function(error, results) {
        should.exist(error);
        done();
      });
    });
    
  });
  
  return describe('storage', function() {
    it('should cache a previously requested resource', function(done) {
      pantry.storage.get(jsonURL, function(error, resource) {
        should.exist(resource);
        resource.should.have.property('options');
        resource.should.have.property('results');
        resource.should.have.property('firstPurchased').with.instanceof(Date);
        resource.should.have.property('lastPurchased').with.instanceof(Date);
        resource.should.have.property('bestBefore').with.instanceof(Date);
        resource.should.have.property('spoilsOn').with.instanceof(Date);
        resource.options.should.have.property('key');
        resource.options.should.have.property('uri');
        resource.options.should.have.property('shelfLife');
        resource.options.should.have.property('maxLife');
        done(error);
      });
    });
    
    it('should return cached results for subsequent calls', function(done) {
      pantry.storage.get(jsonURL, function(first_error, resource) {
        should.exist(resource);
        pantry.fetch(jsonURL, function(second_error, second_results) {
          second_results.should.eql(resource.results);
          done(first_error || second_error);
        });
      });
    });
    
  });
});