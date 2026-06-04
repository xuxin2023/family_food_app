import { describe, it, expect } from '@ohos/hypium';
import { RateLimiter, RateLimitConfig, RateLimitResult } from 'hsp_core';

export default function rateLimiterTest() {
  describe('RateLimiterTest', () => {
    it('should_allow_request_within_limit', 0, () => {
      const limiter = RateLimiter.getInstance();
      const config = new RateLimitConfig();
      config.endpoint = 'test_ep';
      config.maxRequests = 5;
      config.windowMs = 60000;
      limiter.addOrUpdateConfig(config);
      const result = limiter.checkLimit('test_ep');
      expect(result.allowed).assertTrue();
    });

    it('should_block_request_exceeding_limit', 0, () => {
      const limiter = RateLimiter.getInstance();
      const config = new RateLimitConfig();
      config.endpoint = 'test_ep_block';
      config.maxRequests = 2;
      config.windowMs = 60000;
      limiter.addOrUpdateConfig(config);
      limiter.checkLimit('test_ep_block');
      limiter.checkLimit('test_ep_block');
      const result = limiter.checkLimit('test_ep_block');
      expect(result.allowed).assertFalse();
    });

    it('should_allow_unknown_endpoint', 0, () => {
      const limiter = RateLimiter.getInstance();
      const result = limiter.checkLimit('unknown_endpoint_xyz');
      expect(result.allowed).assertTrue();
    });
  });
}
