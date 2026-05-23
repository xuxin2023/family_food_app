/** Highest positive signed 32-bit float value */
// TS2ArkTS-SessionId-1
const maxInt = 2147483647; // aka. 0x7FFFFFFF or 2^31-1

/** Bootstring parameters */
// TS2ArkTS-SessionId-2
const base = 36;
// TS2ArkTS-SessionId-3
const tMin = 1;
// TS2ArkTS-SessionId-4
const tMax = 26;
// TS2ArkTS-SessionId-5
const skew = 38;
// TS2ArkTS-SessionId-6
const damp = 700;
// TS2ArkTS-SessionId-7
const initialBias = 72;
// TS2ArkTS-SessionId-8
const initialN = 128; // 0x80
// TS2ArkTS-SessionId-9
const delimiter = '-'; // '\x2D'

/** Regular expressions */
// TS2ArkTS-SessionId-10
const regexPunycode = /^xn--/;
// TS2ArkTS-SessionId-11
const regexNonASCII = /[^\0-\x7F]/; // Note: U+007F DEL is excluded too.
// TS2ArkTS-SessionId-12
const regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g; // RFC 3490 separators

/** Error messages */
// TS2ArkTS-SessionId-13
class Errors {
  'overflow': string = '';
  'not_basic': string = '';
  'invalid_input': string = '';
}

// TS2ArkTS-SessionId-32
const errors: Errors = {
  'overflow': 'Overflow: input needs wider integers to process',
  'not_basic': 'Illegal input >= 0x80 (not a basic code point)',
  'invalid_input': 'Invalid input',
};

/** Convenience shortcuts */
// TS2ArkTS-SessionId-14
const baseMinusTMin = base - tMin;
// TS2ArkTS-SessionId-15
const floor = Math.floor;
// TS2ArkTS-SessionId-16
const stringFromCharCode = String.fromCharCode;

/*--------------------------------------------------------------------------*/

/**
 * A generic error utility function.
 * @private
 * @param {String} type The error type.
 * @returns {Error} Throws a `RangeError` with the applicable error message.
 */
// TS2ArkTS-SessionId-17

function error(type: string) {
  if (type === 'overflow') {
    throw new RangeError(errors.overflow);
  } else if (type === 'not-basic') {
    throw new RangeError(errors.not_basic);
  } else if (type === 'invalid-input') {
    throw new RangeError(errors.invalid_input);
  }
}

/**
 * A generic `Array#map` utility function.
 * @private
 * @param {Array} array The array to iterate over.
 * @param {Function} callback The function that gets called for every array
 * item.
 * @returns {Array} A new array of values returned by the callback function.
 */
// TS2ArkTS-SessionId-18
function map<T, U>(array: T[], callback: (item: T) => U): U[] {
  const result: U[] = [];
  let length: number = array.length;
  while (length--) {
    result[length] = callback(array[length]);
  }
  return result;
}

/**
 * A simple `Array#map`-like wrapper to work with domain name strings or email
 * addresses.
 * @private
 * @param {String} domain The domain name or email address.
 * @param {Function} callback The function that gets called for every
 * character.
 * @returns {String} A new string of characters returned by the callback
 * function.
 */
// TS2ArkTS-SessionId-19

function mapDomain(domain: string, callback: (label: string) => string): string {
  const parts = domain.split('@');
  let result = '';
  if (parts.length > 1) {
    // In email addresses, only the domain name should be punycoded. Leave
    // the local part (i.e. everything up to `@`) intact.
    result = parts[0] + '@';
    domain = parts[1];
  }
  // Avoid `split(regex)` for IE8 compatibility. See #17.
  domain = domain.replace(regexSeparators, '\x2E');
  const labels = domain.split('.');
  const encoded = map(labels, callback).join('.');
  return result + encoded;
}

/**
 * Creates an array containing the numeric code points of each Unicode
 * character in the string. While JavaScript uses UCS-2 internally,
 * this function will convert a pair of surrogate halves (each of which
 * UCS-2 exposes as separate characters) into a single code point,
 * matching UTF-16.
 * @see `punycode.ucs2.encode`
 * @see <https://mathiasbynens.be/notes/javascript-encoding>
 * @memberOf punycode.ucs2
 * @name decode
 * @param {String} string The Unicode input string (UCS-2).
 * @returns {Array} The new array of code points.
 */
// TS2ArkTS-SessionId-20
function ucs2decode(string: string): number[] {
  const output: number[] = [];
  let counter: number = 0;
  const length: number = string.length;
  while (counter < length) {
    const value: number = string.charCodeAt(counter++);
    if (value >= 0xd800 && value <= 0xdbff && counter < length) {
      // It's a high surrogate, and there is a next character.
      const extra: number = string.charCodeAt(counter++);
      if ((extra & 0xfc00) == 0xdc00) {
        // Low surrogate.
        output.push(((value & 0x3ff) << 10) + (extra & 0x3ff) + 0x10000);
      } else {
        // It's an unmatched surrogate; only append this code unit, in case the
        // next code unit is the high surrogate of a surrogate pair.
        output.push(value);
        counter--;
      }
    } else {
      output.push(value);
    }
  }
  return output;
}

/**
 * Creates a string based on an array of numeric code points.
 * @see `punycode.ucs2.decode`
 * @memberOf punycode.ucs2
 * @name encode
 * @param {Array} codePoints The array of numeric code points.
 * @returns {String} The new Unicode string (UCS-2).
 */
// TS2ArkTS-SessionId-21
const ucs2encode = (codePoints: number[]) => {
  let result = '';
  for (let i = 0; i < codePoints.length; i++) {
    result += String.fromCodePoint(codePoints[i]);
  }
  return result;
};

/**
 * Converts a basic code point into a digit/integer.
 * @see `digitToBasic()`
 * @private
 * @param {Number} codePoint The basic numeric code point value.
 * @returns {Number} The numeric value of a basic code point (for use in
 * representing integers) in the range `0` to `base - 1`, or `base` if
 * the code point does not represent a value.
 */
// TS2ArkTS-SessionId-22
const basicToDigit = (codePoint: number): number => {
  if (codePoint >= 0x30 && codePoint < 0x3a) {
    return 26 + (codePoint - 0x30);
  }
  if (codePoint >= 0x41 && codePoint < 0x5b) {
    return codePoint - 0x41;
  }
  if (codePoint >= 0x61 && codePoint < 0x7b) {
    return codePoint - 0x61;
  }
  return base;
};

/**
 * Converts a digit/integer into a basic code point.
 * @see `basicToDigit()`
 * @private
 * @param {Number} digit The numeric value of a basic code point.
 * @returns {Number} The basic code point whose value (when used for
 * representing integers) is `digit`, which needs to be in the range
 * `0` to `base - 1`. If `flag` is non-zero, the uppercase form is
 * used; else, the lowercase form is used. The behavior is undefined
 * if `flag` is non-zero and `digit` has no uppercase form.
 */
// TS2ArkTS-SessionId-23
const digitToBasic = (digit: number, flag: number): number => {
  //  0..25 map to ASCII a..z or A..Z
  // 26..35 map to ASCII 0..9
  return digit + 22 + 75 * (digit < 26 ? 1 : 0) - ((flag != 0 ? 1 : 0) << 5);
};

/**
 * Bias adaptation function as per section 3.4 of RFC 3492.
 * https://tools.ietf.org/html/rfc3492#section-3.4
 * @private
 */
// TS2ArkTS-SessionId-24
const adapt = (delta: number, numPoints: number, firstTime: boolean): number => {
  let k: number = 0;
  delta = firstTime ? floor(delta / damp) : delta >> 1;
  delta += floor(delta / numPoints);
  for (; /* no initialization */ delta > (baseMinusTMin * tMax) >> 1; k += base) {
    delta = floor(delta / baseMinusTMin);
  }
  return floor(k + ((baseMinusTMin + 1) * delta) / (delta + skew));
};

/**
 * Converts a Punycode string of ASCII-only symbols to a string of Unicode
 * symbols.
 * @memberOf punycode
 * @param {String} input The Punycode string of ASCII-only symbols.
 * @returns {String} The resulting string of Unicode symbols.
 */
// TS2ArkTS-SessionId-25

const decode = (input: string): string => {
  // Don't use UCS-2.
  const output: number[] = [];
  const inputLength = input.length;
  let i = 0;
  let n = initialN;
  let bias = initialBias;

  // Handle the basic code points: let `basic` be the number of input code
  // points before the last delimiter, or `0` if there is none, then copy
  // the first basic code points to the output.

  let basic = input.lastIndexOf(delimiter);
  if (basic < 0) {
    basic = 0;
  }

  for (let j = 0; j < basic; ++j) {
    // if it's not a basic code point
    if (input.charCodeAt(j) >= 0x80) {
      error('not-basic');
    }
    output.push(input.charCodeAt(j));
  }

  // Main decoding loop: start just after the last delimiter if any basic code
  // points were copied; start at the beginning otherwise.

  for (let index = basic > 0 ? basic + 1 : 0; index < inputLength /* no final expression */; ) {
    // `index` is the index of the next character to be consumed.
    // Decode a generalized variable-length integer into `delta`,
    // which gets added to `i`. The overflow checking is easier
    // if we increase `i` as we go, then subtract off its starting
    // value at the end to obtain `delta`.
    const oldi = i;
    for (let w = 1, k = base /* no condition */; ; k += base) {
      if (index >= inputLength) {
        error('invalid-input');
      }

      const digit = basicToDigit(input.charCodeAt(index++));

      if (digit >= base) {
        error('invalid-input');
      }
      if (digit > floor((maxInt - i) / w)) {
        error('overflow');
      }

      i += digit * w;
      const t = k <= bias ? tMin : k >= bias + tMax ? tMax : k - bias;

      if (digit < t) {
        break;
      }

      const baseMinusT = base - t;
      if (w > floor(maxInt / baseMinusT)) {
        error('overflow');
      }

      w *= baseMinusT;
    }

    const out = output.length + 1;
    bias = adapt(i - oldi, out, oldi == 0);

    // `i` was supposed to wrap around from `out` to `0`,
    // incrementing `n` each time, so we'll fix that now:
    if (floor(i / out) > maxInt - n) {
      error('overflow');
    }

    n += floor(i / out);
    i %= out;

    // Insert `n` at position `i` of the output.
    output.splice(i++, 0, n);
  }

  return String.fromCodePoint(...output);
};

/**
 * Converts a string of Unicode symbols (e.g. a domain name label) to a
 * Punycode string of ASCII-only symbols.
 * @memberOf punycode
 * @param {String} input The string of Unicode symbols.
 * @returns {String} The resulting Punycode string of ASCII-only symbols.
 */
// TS2ArkTS-SessionId-26

const encode = (input: string): string => {
  const output: string[] = [];
  input = ucs2decode(input).join('');

  const inputLength: number = input.length;

  let n: number = initialN;
  let delta: number = 0;
  let bias: number = initialBias;

  for (const currentValue of input) {
    if (currentValue.charCodeAt(0) < 0x80) {
      output.push(currentValue);
    }
  }

  const basicLength: number = output.length;
  let handledCPCount: number = basicLength;

  if (basicLength) {
    output.push(delimiter);
  }

  while (handledCPCount < inputLength) {
    let m: number = maxInt;
    for (const currentValue of input) {
      const codePoint: number = currentValue.charCodeAt(0);
      if (codePoint >= n && codePoint < m) {
        m = codePoint;
      }
    }

    const handledCPCountPlusOne: number = handledCPCount + 1;
    if (m - n > Math.floor((maxInt - delta) / handledCPCountPlusOne)) {
      error('overflow');
    }

    delta += (m - n) * handledCPCountPlusOne;
    n = m;

    for (const currentValue of input) {
      const codePoint: number = currentValue.charCodeAt(0);
      if (codePoint < n && ++delta > maxInt) {
        error('overflow');
      }
      if (codePoint === n) {
        let q: number = delta;
        for (let k: number = base /* no condition */; ; k += base) {
          const t: number = k <= bias ? tMin : k >= bias + tMax ? tMax : k - bias;
          if (q < t) {
            break;
          }
          const qMinusT: number = q - t;
          const baseMinusT: number = base - t;
          output.push(stringFromCharCode(digitToBasic(t + (qMinusT % baseMinusT), 0)));
          q = Math.floor(qMinusT / baseMinusT);
        }

        output.push(stringFromCharCode(digitToBasic(q, 0)));
        bias = adapt(delta, handledCPCountPlusOne, handledCPCount === basicLength);
        delta = 0;
        ++handledCPCount;
      }
    }

    ++delta;
    ++n;
  }
  return output.join('');
};

/**
 * Converts a Punycode string representing a domain name or an email address
 * to Unicode. Only the Punycoded parts of the input will be converted, i.e.
 * it doesn't matter if you call it on a string that has already been
 * converted to Unicode.
 * @memberOf punycode
 * @param {String} input The Punycoded domain name or email address to
 * convert to Unicode.
 * @returns {String} The Unicode representation of the given Punycode
 * string.
 */
// TS2ArkTS-SessionId-27
const toUnicode = (input: string): string => {
  return mapDomain(input, (string: string): string => {
    return regexPunycode.test(string) ? decode(string.slice(4).toLowerCase()) : string;
  });
};

/**
 * Converts a Unicode string representing a domain name or an email address to
 * Punycode. Only the non-ASCII parts of the domain name will be converted,
 * i.e. it doesn't matter if you call it with a domain that's already in
 * ASCII.
 * @memberOf punycode
 * @param {String} input The domain name or email address to convert, as a
 * Unicode string.
 * @returns {String} The Punycode representation of the given domain name or
 * email address.
 */
// TS2ArkTS-SessionId-28
const toASCII = (input: string) => {
  return mapDomain(input, (string: string) => {
    return regexNonASCII.test(string) ? 'xn--' + encode(string) : string;
  });
};

/*--------------------------------------------------------------------------*/

/** Define the public API */
// TS2ArkTS-SessionId-29

class Ucs2 {
  decode: Function = ucs2decode;
  encode: Function = ucs2encode;
}

// TS2ArkTS-SessionId-2

class Punycode {
  version: string = '1.0.0';
  ucs2: Ucs2 = {
    decode: ucs2decode,
    encode: ucs2encode,
  };
  decode: Function = decode;
  encode: Function = encode;
  toASCII: Function = toASCII;
  toUnicode: Function = toUnicode;
}

// TS2ArkTS-SessionId-30

export { ucs2decode, ucs2encode, decode, encode, toASCII, toUnicode };

// TS2ArkTS-SessionId-31
export default Punycode;
