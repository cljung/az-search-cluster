//
// This is the tinyest reverse proxy that forwards http port 80 to the ElasticSearch Load Balancer port 9200
//

// FQDN to what we will listen to
var proxyFqdn = process.argv[2];
// Where to forward to in format http://x.y.z.w:port
var internalIpAddr = process.argv[3];

console.log(proxyFqdn);
console.log(internalIpAddr);

// Start Redbird
var proxy = require('redbird')({port: 80});

// register
proxy.register( proxyFqdn, internalIpAddr );