/**
* Copyright 2017 HUAWEI. All Rights Reserved.
*
* SPDX-License-Identifier: Apache-2.0
*
*/

'use strict';

module.exports.info  = 'opening accounts';

let accounts = [];
let bc, contx;
module.exports.init = function(blockchain, context, args) {
    if(!args.hasOwnProperty('money')) {
        return Promise.reject(new Error('simple.open - "money" is missed in the arguments'));
    }

    bc = blockchain;
    contx = context;
    return Promise.resolve();
};

/**
 * Generate string by picking characters from dic variable
 * @param {*} number character to select
 * @returns {String} string generated based on @param number
 */
/**
 * Generate unique account key for the transaction
 * @returns {String} account key
 */

module.exports.run = function() {
    return bc.invokeSmartContract(contx, 'sacc', 'v0', '{"Args": ["a", "100"]}', 30);
};

module.exports.end = function() {
    return Promise.resolve();
};

module.exports.accounts = accounts;
