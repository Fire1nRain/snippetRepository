const httpUtil = require('./httpUtil');
const APIs = require('./APIs');
const fs = require('fs');
const Q = require('q');

let cache = {};

module.exports = {
    requestToken: function (code) {
        let query;
        if (code)
            query = `grant_type=authorization_code&code=${code}`;
        else
            query = `grant_type=refresh_token&refresh_token=${this.refreshToken}`;

        return httpUtil.getToken(query)
            .then(value => {
                let {access_token, expires_in, refresh_token} = JSON.parse(value);
                this.accessToken = access_token;
                this.refreshToken = refresh_token;
                this.setTokenRefresh(expires_in);

                let date = Date.now() + (expires_in - 15) * 1000;
                date = new Date(date);

                saveToken({refreshToken: this.refreshToken, accessToken: this.accessToken, expireDate: date});
                return this.accessToken;
            })
    },
    setTokenRefresh: function (expireIn) {
        setTimeout(() => {
            httpUtil.getToken(`grant_type=refresh_token&refresh_token=${this.refreshToken}`)
                .then(value => {
                    let {access_token, expireIn, refresh_token} = JSON.parse(value);
                    this.accessToken = access_token;
                    this.refreshToken = refresh_token;
                    this.setTokenRefresh(expireIn);
                })
        }, (expireIn - 15) * 1000)
    },
    loadToken: function () {
        let defer = Q.defer();
        if (this.accessToken)
            defer.resolve(this.accessToken);
        else {
            try {
                let token = fs.readFileSync('./token');
                token = JSON.parse(token);
                this.accessToken = token.accessToken;
                this.refreshToken = token.refreshToken;
                let nowDate = new Date();
                let expireDate = new Date(token.expireDate);
                if (expireDate < nowDate) {
                    this.requestToken()
                        .then(value => {
                            return this.getCharacterID()
                        })
                        .then(value => {
                            defer.resolve(this.accessToken)
                        })
                } else {
                    this.setTokenRefresh((expireDate.getTime() - nowDate.getTime()) / 1000);
                    this.loadCache();
                    defer.resolve(token.accessToken)
                }
            } catch (e) {
                console.log(e);
                defer.reject(undefined)
            }
        }
        return defer.promise;
    },
    getCharacterID: function () {
        return httpUtil.getCharacterID(this.accessToken).then(value => {
            this.characterInfo = JSON.parse(value);
            cacheInfo("characterInfo", this.characterInfo);
            return this.characterInfo.CharacterID;
        });
    },
    doApiRequest: function (name, data) {
        let obj = APIs;
        name = name.split('.');
        for (let part of name) {
            obj = obj[part];
            if (!obj)
                break;
        }
        if (obj) {
            obj = Object.create(obj);
            // obj = Object.assign({},obj);
            obj.path = obj.path.replace("${characterID}", this.characterInfo.CharacterID);
            if (data)
                for (let item of Object.keys(data))
                    obj.path = obj.path.replace(`\${${item}}`, data[item])
            obj.host = APIs.host;
            obj.path = `${obj.path}?datasource=${APIs.dataSource}&token=${this.accessToken}&${obj.query ? obj.query : ''}&language=en-us`;
            return httpUtil.request(obj, data).then(value => {
                return obj.postProcess(value)
            });
        } else
            throw new Error(`Cannot found specified api, name: ${name}`);
    },
    loadCache: function () {
        let cacheFile = fs.readFileSync('./cache');
        try {
            cache = JSON.parse(cacheFile);
            this.characterInfo = cache.characterInfo;
        } catch (e) {
            console.error(e);
            throw new Error(e)
        }
    }
};

function saveToken(token) {
    let tokenFile = fs.createWriteStream('./token', {flags: 'w'});
    tokenFile.end(JSON.stringify(token));
}

function cacheInfo(typeOfInfo, info) {
    info.cachedTime = new Date();
    cache[typeOfInfo] = info;
    let cacheFile = fs.createWriteStream('./cache', {flags: 'w'});
    cacheFile.end(JSON.stringify(cache));
}
