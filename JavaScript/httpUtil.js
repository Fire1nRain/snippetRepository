const https = require('https');
const Q = require('q');
const config = require('../config');

module.exports = {
    getToken: function (query) {
        let payload = {
            host: 'login.eveonline.com',
            path: `/oauth/token?${query}`,
            headers: {
                'Authorization': `Basic ${Buffer.from(`${config.Client_ID}:${config.Client_Secret}`).toString('base64')}`,
            }
        };
        return this.request(payload).then(value => {
            return value;
        }, reason => {
            throw reason;
        });
    },
    getCharacterID: function (token) {
        let payload = {
            host: 'esi.tech.ccp.is',
            path: '/verify',
            method: "GET",
            headers: {
                'Authorization': `Bearer ${token}`,
            }
        };
        return this.request(payload).then(value => {
            return value;
        }, reason => {
            throw reason;
        });
    },
    request: function (payload, data) {
        let defer = Q.defer();

        let {host, path, method, headers} = payload;

        headers = Object.assign(headers ? headers : {}, {'Content-Type': 'application/x-www-form-urlencoded'});

        if (!method)
            method = 'POST';

        let request = https.request({
            host: host,
            path: path,
            method: method,
            headers: headers
        }, function (res) {
            res.setEncoding('utf8');
            let data = "";
            res.on('data', chunk => {
                data += chunk;
            });
            res.on('end', (value) => {
                defer.resolve(data);
            })
        });

        request.on('error', err => {
            defer.reject(err);
        });

        if (data)
            request.write(JSON.stringify(data));

        request.end();

        return defer.promise;
    }
};
