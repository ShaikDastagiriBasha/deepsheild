import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 }, // ramp up to 50 users
    { duration: '1m', target: 100 }, // load test for 1 min with 100 users
    { duration: '30s', target: 0 },  // ramp down to 0
  ],
};

export default function () {
  // Assuming a generic GET request. Update with your backend functions if any.
  // DO NOT run this against production Firebase without ensuring billing boundaries.
  const res = http.get('https://example.com/api/health');
  
  check(res, {
    'status was 200': (r) => r.status == 200,
    'transaction time OK': (r) => r.timings.duration < 250, // 250ms SLA
  });
  
  sleep(1);
}
