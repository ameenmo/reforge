// utils.js - A grab bag of utility functions with no organization

var fs = require('fs');
var path = require('path');
var crypto = require('crypto');

// String utilities
function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function capitalizeWords(str) {
    if (!str) return '';
    return str.split(' ').map(function(word) {
        return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    }).join(' ');
}

function truncate(str, length) {
    if (!str) return '';
    if (str.length <= length) return str;
    return str.substring(0, length) + '...';
}

function slugify(str) {
    return str.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

function camelCase(str) {
    return str.replace(/[-_\s]+(.)?/g, function(match, chr) {
        return chr ? chr.toUpperCase() : '';
    });
}

function snakeCase(str) {
    return str.replace(/[A-Z]/g, function(letter) {
        return '_' + letter.toLowerCase();
    }).replace(/^_/, '');
}

function kebabCase(str) {
    return str.replace(/[A-Z]/g, function(letter) {
        return '-' + letter.toLowerCase();
    }).replace(/^-/, '');
}

function padLeft(str, length, char) {
    char = char || ' ';
    while (str.length < length) {
        str = char + str;
    }
    return str;
}

function padRight(str, length, char) {
    char = char || ' ';
    while (str.length < length) {
        str = str + char;
    }
    return str;
}

function repeat(str, times) {
    var result = '';
    for (var i = 0; i < times; i++) {
        result += str;
    }
    return result;
}

function reverse(str) {
    return str.split('').reverse().join('');
}

function countOccurrences(str, substr) {
    var count = 0;
    var pos = 0;
    while (true) {
        pos = str.indexOf(substr, pos);
        if (pos >= 0) {
            count++;
            pos += substr.length;
        } else {
            break;
        }
    }
    return count;
}

function escapeHtml(str) {
    return str.replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;')
              .replace(/'/g, '&#039;');
}

function unescapeHtml(str) {
    return str.replace(/&amp;/g, '&')
              .replace(/&lt;/g, '<')
              .replace(/&gt;/g, '>')
              .replace(/&quot;/g, '"')
              .replace(/&#039;/g, "'");
}

// Number utilities
function clamp(num, min, max) {
    return Math.min(Math.max(num, min), max);
}

function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function roundTo(num, decimals) {
    var factor = Math.pow(10, decimals);
    return Math.round(num * factor) / factor;
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function percentage(value, total) {
    if (total === 0) return 0;
    return roundTo((value / total) * 100, 2);
}

function sum(arr) {
    var total = 0;
    for (var i = 0; i < arr.length; i++) {
        total += arr[i];
    }
    return total;
}

function average(arr) {
    if (arr.length === 0) return 0;
    return sum(arr) / arr.length;
}

function median(arr) {
    var sorted = arr.slice().sort(function(a, b) { return a - b; });
    var mid = Math.floor(sorted.length / 2);
    if (sorted.length % 2 === 0) {
        return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
}

function standardDeviation(arr) {
    var avg = average(arr);
    var squareDiffs = arr.map(function(value) {
        var diff = value - avg;
        return diff * diff;
    });
    return Math.sqrt(average(squareDiffs));
}

// Array utilities
function flatten(arr) {
    var result = [];
    for (var i = 0; i < arr.length; i++) {
        if (Array.isArray(arr[i])) {
            result = result.concat(flatten(arr[i]));
        } else {
            result.push(arr[i]);
        }
    }
    return result;
}

function unique(arr) {
    var seen = {};
    var result = [];
    for (var i = 0; i < arr.length; i++) {
        if (!seen[arr[i]]) {
            seen[arr[i]] = true;
            result.push(arr[i]);
        }
    }
    return result;
}

function chunk(arr, size) {
    var result = [];
    for (var i = 0; i < arr.length; i += size) {
        result.push(arr.slice(i, i + size));
    }
    return result;
}

function shuffle(arr) {
    var result = arr.slice();
    for (var i = result.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var temp = result[i];
        result[i] = result[j];
        result[j] = temp;
    }
    return result;
}

function groupBy(arr, key) {
    var result = {};
    for (var i = 0; i < arr.length; i++) {
        var group = arr[i][key];
        if (!result[group]) {
            result[group] = [];
        }
        result[group].push(arr[i]);
    }
    return result;
}

function pluck(arr, key) {
    return arr.map(function(item) {
        return item[key];
    });
}

function compact(arr) {
    return arr.filter(function(item) {
        return item != null && item !== false && item !== '';
    });
}

function intersection(arr1, arr2) {
    return arr1.filter(function(item) {
        return arr2.indexOf(item) !== -1;
    });
}

function difference(arr1, arr2) {
    return arr1.filter(function(item) {
        return arr2.indexOf(item) === -1;
    });
}

function zip(arr1, arr2) {
    var result = [];
    var length = Math.min(arr1.length, arr2.length);
    for (var i = 0; i < length; i++) {
        result.push([arr1[i], arr2[i]]);
    }
    return result;
}

// Object utilities
function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj));
}

function merge(target, source) {
    for (var key in source) {
        if (source.hasOwnProperty(key)) {
            if (typeof source[key] === 'object' && source[key] !== null && !Array.isArray(source[key])) {
                target[key] = target[key] || {};
                merge(target[key], source[key]);
            } else {
                target[key] = source[key];
            }
        }
    }
    return target;
}

function pick(obj, keys) {
    var result = {};
    for (var i = 0; i < keys.length; i++) {
        if (obj.hasOwnProperty(keys[i])) {
            result[keys[i]] = obj[keys[i]];
        }
    }
    return result;
}

function omit(obj, keys) {
    var result = {};
    for (var key in obj) {
        if (obj.hasOwnProperty(key) && keys.indexOf(key) === -1) {
            result[key] = obj[key];
        }
    }
    return result;
}

function isEmpty(obj) {
    if (obj == null) return true;
    if (Array.isArray(obj) || typeof obj === 'string') return obj.length === 0;
    return Object.keys(obj).length === 0;
}

function objectToQueryString(obj) {
    var parts = [];
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(obj[key]));
        }
    }
    return parts.join('&');
}

function queryStringToObject(str) {
    var result = {};
    str = str.replace(/^\?/, '');
    var pairs = str.split('&');
    for (var i = 0; i < pairs.length; i++) {
        var pair = pairs[i].split('=');
        result[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || '');
    }
    return result;
}

// Date utilities
function daysAgo(days) {
    var d = new Date();
    d.setDate(d.getDate() - days);
    return d;
}

function daysBetween(date1, date2) {
    var oneDay = 24 * 60 * 60 * 1000;
    return Math.round(Math.abs((date1 - date2) / oneDay));
}

function isToday(date) {
    var today = new Date();
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear();
}

function isWeekend(date) {
    var day = date.getDay();
    return day === 0 || day === 6;
}

function formatRelativeTime(date) {
    var now = new Date();
    var diffMs = now - date;
    var diffSecs = Math.floor(diffMs / 1000);
    var diffMins = Math.floor(diffSecs / 60);
    var diffHours = Math.floor(diffMins / 60);
    var diffDays = Math.floor(diffHours / 24);

    if (diffSecs < 60) return diffSecs + ' seconds ago';
    if (diffMins < 60) return diffMins + ' minutes ago';
    if (diffHours < 24) return diffHours + ' hours ago';
    if (diffDays < 30) return diffDays + ' days ago';
    return Math.floor(diffDays / 30) + ' months ago';
}

function addDays(date, days) {
    var result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
}

function startOfDay(date) {
    var result = new Date(date);
    result.setHours(0, 0, 0, 0);
    return result;
}

function endOfDay(date) {
    var result = new Date(date);
    result.setHours(23, 59, 59, 999);
    return result;
}

// Validation utilities
function isValidUrl(str) {
    try {
        new URL(str);
        return true;
    } catch (e) {
        return false;
    }
}

function isValidIp(str) {
    var parts = str.split('.');
    if (parts.length !== 4) return false;
    for (var i = 0; i < parts.length; i++) {
        var num = parseInt(parts[i]);
        if (isNaN(num) || num < 0 || num > 255) return false;
    }
    return true;
}

function isValidHexColor(str) {
    return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(str);
}

function isAlphanumeric(str) {
    return /^[a-zA-Z0-9]+$/.test(str);
}

function isNumeric(str) {
    return !isNaN(parseFloat(str)) && isFinite(str);
}

function isCreditCard(str) {
    var cleaned = str.replace(/\D/g, '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    var sum = 0;
    var alternate = false;
    for (var i = cleaned.length - 1; i >= 0; i--) {
        var n = parseInt(cleaned[i]);
        if (alternate) {
            n *= 2;
            if (n > 9) n -= 9;
        }
        sum += n;
        alternate = !alternate;
    }
    return sum % 10 === 0;
}

// File utilities
function readJsonFile(filepath) {
    try {
        var content = fs.readFileSync(filepath, 'utf8');
        return JSON.parse(content);
    } catch (e) {
        return null;
    }
}

function writeJsonFile(filepath, data) {
    fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
}

function fileExists(filepath) {
    try {
        fs.accessSync(filepath);
        return true;
    } catch (e) {
        return false;
    }
}

function getFileSize(filepath) {
    var stats = fs.statSync(filepath);
    return stats.size;
}

function getFileExtension(filepath) {
    return path.extname(filepath).slice(1);
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    var k = 1024;
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Crypto utilities
function md5(str) {
    return crypto.createHash('md5').update(str).digest('hex');
}

function sha256(str) {
    return crypto.createHash('sha256').update(str).digest('hex');
}

function generateToken(length) {
    return crypto.randomBytes(length || 32).toString('hex');
}

function base64Encode(str) {
    return Buffer.from(str).toString('base64');
}

function base64Decode(str) {
    return Buffer.from(str, 'base64').toString('utf8');
}

// Misc utilities
function sleep(ms) {
    return new Promise(function(resolve) {
        setTimeout(resolve, ms);
    });
}

function retry(fn, retries, delay) {
    retries = retries || 3;
    delay = delay || 1000;
    return fn().catch(function(err) {
        if (retries <= 0) throw err;
        return sleep(delay).then(function() {
            return retry(fn, retries - 1, delay);
        });
    });
}

function debounce(fn, wait) {
    var timeout;
    return function() {
        var context = this;
        var args = arguments;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            fn.apply(context, args);
        }, wait);
    };
}

function throttle(fn, limit) {
    var inThrottle;
    return function() {
        var context = this;
        var args = arguments;
        if (!inThrottle) {
            fn.apply(context, args);
            inThrottle = true;
            setTimeout(function() {
                inThrottle = false;
            }, limit);
        }
    };
}

function memoize(fn) {
    var cache = {};
    return function() {
        var key = JSON.stringify(arguments);
        if (cache[key] !== undefined) return cache[key];
        cache[key] = fn.apply(this, arguments);
        return cache[key];
    };
}

function compose() {
    var fns = Array.prototype.slice.call(arguments);
    return function(x) {
        return fns.reduceRight(function(acc, fn) {
            return fn(acc);
        }, x);
    };
}

function pipe() {
    var fns = Array.prototype.slice.call(arguments);
    return function(x) {
        return fns.reduce(function(acc, fn) {
            return fn(acc);
        }, x);
    };
}

// Export everything individually because we never organized this
module.exports.capitalize = capitalize;
module.exports.capitalizeWords = capitalizeWords;
module.exports.truncate = truncate;
module.exports.slugify = slugify;
module.exports.camelCase = camelCase;
module.exports.snakeCase = snakeCase;
module.exports.kebabCase = kebabCase;
module.exports.padLeft = padLeft;
module.exports.padRight = padRight;
module.exports.repeat = repeat;
module.exports.reverse = reverse;
module.exports.countOccurrences = countOccurrences;
module.exports.escapeHtml = escapeHtml;
module.exports.unescapeHtml = unescapeHtml;
module.exports.clamp = clamp;
module.exports.randomInt = randomInt;
module.exports.roundTo = roundTo;
module.exports.formatNumber = formatNumber;
module.exports.percentage = percentage;
module.exports.sum = sum;
module.exports.average = average;
module.exports.median = median;
module.exports.standardDeviation = standardDeviation;
module.exports.flatten = flatten;
module.exports.unique = unique;
module.exports.chunk = chunk;
module.exports.shuffle = shuffle;
module.exports.groupBy = groupBy;
module.exports.pluck = pluck;
module.exports.compact = compact;
module.exports.intersection = intersection;
module.exports.difference = difference;
module.exports.zip = zip;
module.exports.deepClone = deepClone;
module.exports.merge = merge;
module.exports.pick = pick;
module.exports.omit = omit;
module.exports.isEmpty = isEmpty;
module.exports.objectToQueryString = objectToQueryString;
module.exports.queryStringToObject = queryStringToObject;
module.exports.daysAgo = daysAgo;
module.exports.daysBetween = daysBetween;
module.exports.isToday = isToday;
module.exports.isWeekend = isWeekend;
module.exports.formatRelativeTime = formatRelativeTime;
module.exports.addDays = addDays;
module.exports.startOfDay = startOfDay;
module.exports.endOfDay = endOfDay;
module.exports.isValidUrl = isValidUrl;
module.exports.isValidIp = isValidIp;
module.exports.isValidHexColor = isValidHexColor;
module.exports.isAlphanumeric = isAlphanumeric;
module.exports.isNumeric = isNumeric;
module.exports.isCreditCard = isCreditCard;
module.exports.readJsonFile = readJsonFile;
module.exports.writeJsonFile = writeJsonFile;
module.exports.fileExists = fileExists;
module.exports.getFileSize = getFileSize;
module.exports.getFileExtension = getFileExtension;
module.exports.formatFileSize = formatFileSize;
module.exports.md5 = md5;
module.exports.sha256 = sha256;
module.exports.generateToken = generateToken;
module.exports.base64Encode = base64Encode;
module.exports.base64Decode = base64Decode;
module.exports.sleep = sleep;
module.exports.retry = retry;
module.exports.debounce = debounce;
module.exports.throttle = throttle;
module.exports.memoize = memoize;
module.exports.compose = compose;
module.exports.pipe = pipe;
