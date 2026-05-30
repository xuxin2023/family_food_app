export class BusinessError extends Error {
  code: number = 0;
  domain: string = '';
  constructor(message: string, code: number = 0, domain: string = '') {
    super(message);
    this.code = code;
    this.domain = domain;
  }
}
