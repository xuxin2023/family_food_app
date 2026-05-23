# punycode
基于[punycode](https://www.npmjs.com/package/punycode)原库2.3.1版本进行适配, 所有功能代码已经转换为`ArkTS`文件

## Install
```sh
ohpm install punycode
```

## Description

Punycode.js is a robust Punycode converter that fully complies to [RFC 3492](https://tools.ietf.org/html/rfc3492) and [RFC 5891](https://tools.ietf.org/html/rfc5891).

```typescript
import { ucs2decode, ucs2encode, decode, encode, toASCII, toUnicode } from 'punycode';
```

## API

### `decode(string)`

Converts a Punycode string of ASCII symbols to a string of Unicode symbols.

```typescript
// decode domain name parts
decode('maana-pta'); // 'mañana'
decode('--dqo34k'); // '☃-⌘'
```

### `encode(string)`

Converts a string of Unicode symbols to a Punycode string of ASCII symbols.

```typescript
// encode domain name parts
encode('mañana'); // 'maana-pta'
encode('☃-⌘'); // '--dqo34k'
```

### `toUnicode(input)`

Converts a Punycode string representing a domain name or an email address to Unicode. Only the Punycoded parts of the input will be converted, i.e. it doesn’t matter if you call it on a string that has already been converted to Unicode.

```typescript
// decode domain names
toUnicode('xn--maana-pta.com');
// → 'mañana.com'
toUnicode('xn----dqo34k.com');
// → '☃-⌘.com'

// decode email addresses
toUnicode('джумла@xn--p-8sbkgc5ag7bhce.xn--ba-lmcq');
// → 'джумла@джpумлатест.bрфa'
```

### `toASCII(input)`

Converts a lowercased Unicode string representing a domain name or an email address to Punycode. Only the non-ASCII parts of the input will be converted, i.e. it doesn’t matter if you call it with a domain that’s already in ASCII.

```typescript
// encode domain names
toASCII('mañana.com');
// → 'xn--maana-pta.com'
toASCII('☃-⌘.com');
// → 'xn----dqo34k.com'

// encode email addresses
toASCII('джумла@джpумлатест.bрфa');
// → 'джумла@xn--p-8sbkgc5ag7bhce.xn--ba-lmcq'
```


## Author

| [![twitter/mathias](https://gravatar.com/avatar/24e08a9ea84deb17ae121074d0f17125?s=70)](https://twitter.com/mathias "Follow @mathias on Twitter") |
|---|
| [Mathias Bynens](https://mathiasbynens.be/) |

## License

Punycode.js is available under the [MIT](https://mths.be/mit) license.
