const tokenUtil = require('./tokenUtil');
const fs = require('fs');
const Q = require('q');

module.exports = {
    loadNames: function () {
        try {
            this.names = fs.readFileSync('names');
            this.names = JSON.parse(this.names);
        } catch (e) {
            console.error(e);
            this.names = {}
        }
    },
    getNames: function (ids) {
        let defer = Q.defer();
        if (!this.names)
            this.loadNames();
        let lookUps = [];
        let results = {};
        ids.forEach(item => {
            if (this.names[item])
                results[item] = this.names[item];
            else
                lookUps.push(item)
        });
        if (lookUps.length > 0) {
            tokenUtil.doApiRequest('Universe.Names', lookUps)
                .then(value => {
                    value = JSON.parse(value);
                    value.forEach(item => {
                        this.names[item.id] = item;
                        results[item.id] = item;
                    });
                    this.saveCache();
                    defer.resolve(results)
                }, reason => {
                    defer.reject(reason)
                })
        } else
            defer.resolve(results);
        return defer.promise;
    },
    getName: function (id, api, data) {
        let defer = Q.defer();
        if (!this.names)
            this.loadNames();
        if (!this.names[id] || this.names[id] === undefined)
            tokenUtil.doApiRequest(api, data)
                .then(value => {
                    value = JSON.parse(value);
                    if (value.name) {
                        value.isNew = true;
                        defer.resolve(value);
                    } else {
                        throw new Error("Failed to get name" + JSON.stringify(value))
                    }
                });
        else
            defer.resolve(this.names[id]);
        return defer.promise;
    },
    getStructureName: function (id) {
        return this.getName(id, "Universe.System", {structure_id: id})
            .then(value => {
                if (value.isNew) {
                    this.names[id] = {
                        name: value.name
                    };
                    this.saveCache();
                }
                return this.names[id];
            });
    },
    getStationName: function (id) {
        return this.getName(id, "Universe.Station", {station_id: id})
            .then(value => {
                if (value.isNew) {
                    this.names[id] = {
                        name: value.name
                    };
                    this.saveCache();
                }
                return this.names[id];
            });
    },
    getSystemName: function (id) {
        return this.getName(id, "Universe.Structure", {system_id: id})
            .then(value => {
                if (value.isNew) {
                    this.names[id] = {
                        id: id,
                        constellationID: value.constellationID || value.constellation_id,
                        name: value.name,
                        security: value.security ? value.security : value.security_status.toFixed(2),

                    };
                    this.saveCache();
                }
                return this.checkSystemFullName(id)
            })
    },
    saveCache: function () {
        let cacheFile = fs.createWriteStream('./names', {flags: 'w'});
        cacheFile.end(JSON.stringify(this.names));
    },
    checkSystemFullName: function (id) {
        let defer = Q.defer();
        if (this.names[id].FullName)
            defer.resolve(this.names[id]);
        else {
            tokenUtil.doApiRequest('Universe.Constellation', {constellation_id: this.names[id].constellationID})
                .then(value => {
                    value = JSON.parse(value);
                    this.names[id].constellationName = value.name;
                    this.names[id].regionID = value.region_id;
                    return tokenUtil.doApiRequest('Universe.Region', {region_id: value.region_id})
                }, reason => {
                    throw reason
                })
                .then(value => {
                    value = JSON.parse(value);
                    this.names[id].regionName = value.name;
                    this.names[id].FullName = `${value.name} > ${this.names[id].constellationName} > ${this.names[id].name}`;
                    this.saveCache();
                    defer.resolve(this.names[id]);
                }, reason => {
                    throw reason
                })
                .catch(reason => {
                    defer.reject(reason);
                });
        }
        return defer.promise;
    }
};

