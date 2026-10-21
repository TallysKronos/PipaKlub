import test from 'node:test';
import assert from 'node:assert/strict';
import {localSessionCookies} from './scripts/local-session-cookies.mjs';
test('local browser sessions remain isolated across ports without accepting legacy credentials',()=>{
 const a=localSessionCookies(5201),b=localSessionCookies(5203);
 const jar='pipa_access=legacy; local5201_pipa_access=one; local5203_pipa_access=two; local5203_pipa_refresh=renew; theme=sky';
 assert.match(a.incoming(jar),/(^|; )pipa_access=one(;|$)/);assert.doesNotMatch(a.incoming(jar),/(^|; )pipa_access=(two|legacy)(;|$)/);
 assert.match(b.incoming(jar),/(^|; )pipa_access=two(;|$)/);assert.match(b.incoming(jar),/(^|; )pipa_refresh=renew(;|$)/);
 assert.equal(b.outgoing('pipa_access=; Max-Age=0; HttpOnly; SameSite=Lax'),'local5203_pipa_access=; Max-Age=0; HttpOnly; SameSite=Lax');
 assert.equal(b.incoming(), '');
});
