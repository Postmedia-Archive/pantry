var mockCount = 0;

module.exports = function(state, results) {
  this.state = state != null ? state : 'fresh';
  this.results = results;
  this.options = {
    shelfLife: 60,
    maxLife: 120,
    key: "ID-" + (mockCount++)
  };
  this.firstPurchased = new Date();
  this.lastPurchased = new Date(this.firstPurchased);
  this.bestBefore = new Date(this.firstPurchased);
  this.spoilsOn = new Date(this.firstPurchased);
  switch (this.state) {
    case 'expired':
      this.bestBefore.setHours(this.bestBefore.getHours() - 1);
      this.spoilsOn.setHours(this.spoilsOn.getHours() + 1);
      break;
    case 'spoiled':
      this.bestBefore.setHours(this.bestBefore.getHours() - 1);
      this.spoilsOn.setHours(this.spoilsOn.getHours() - 2);
      break;
    default:
      this.bestBefore.setHours(this.bestBefore.getHours() + 1);
      this.spoilsOn.setHours(this.spoilsOn.getHours() + 2);
  }
};