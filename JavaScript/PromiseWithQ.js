let Q = require('q');
let fs = require('fs');

let rules = [
    {
        /**
         * each rule is wrapped with Q.fcall
         * Q.fcall turns a normal function into a promise returning one
         * normal function will resolve the promise when returning
         * and will reject the promise when throwing
         */
        rule: function () {
            return "Yes";
            // throw "No"
        }
    }, {
        rule: function () {
            /**
             * returns a promise created by Q.any
             * Q.any(promises) will be resolved on the first promise being resolved
             * and will reject when all promises are rejected
             *
             * Q.nfcall is the node version of Q.fcall
             */
            return Q.any([
                Q.nfcall(fs.access, "./binff", fs.constants.W_OK),
                Q.nfcall(fs.access, "./publffic", fs.constants.W_OK)
                /**
                 * the function actually returns promise.then/fail
                 * promise.then/fail returns a new promise,
                 * it will be fulfilled when the specified function returns or finishes
                 * it will be rejected when the function throws an error
                 */
            ]).fail(function () {
                throw "No folders found!";
            });
        }
    }
];

//timeout used to wait for debugger to attach
setTimeout(function () {
    let promises = [];
    for (let rule of rules) {
        promises.push(Q.fcall(rule.rule));
    }
    Q.allSettled(promises)
        .then(function (results) {
            for (let result of results)
                if (result.state !== "fulfilled")
                    console.log("[main] " + result.reason);
        })
}, 500);