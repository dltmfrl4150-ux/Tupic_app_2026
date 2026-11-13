/**
 * Firestore security rules tests for publicProfiles + shareGroups/sharePosts.
 *
 * Run:
 *   firebase emulators:exec --only firestore "node firestore/rules.test.js"
 */
const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'tupic-project';
const RULES = readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8');

function profile(uid, nickname) {
  return {
    uid,
    nickname,
    updatedAt: new Date(),
    createdAt: new Date(),
  };
}

function snapshot() {
  return {
    channelName: 'Shared Channel',
    isKidsChannel: false,
    playOrder: 'oldestAdded',
    videos: [{ youtubeVideoId: 'abc12345678', title: 'Vid', manualOrder: 0 }],
  };
}

function postPayload(uid, channelId, version, extra = {}) {
  return {
    groupId: `${uid}__${channelId}`,
    ownerUid: uid,
    version,
    title: 'Shared Channel',
    category: 'music',
    isKids: false,
    videoCount: 1,
    snapshot: snapshot(),
    createdAt: new Date(),
    status: 'published',
    ...extra,
  };
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES, host: '127.0.0.1', port: 8080 },
  });

  try {
    await testEnv.clearFirestore();

    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    const guest = testEnv.unauthenticatedContext();

    // --- publicProfiles ---
    await assertSucceeds(
      alice.firestore().collection('publicProfiles').doc('alice').set(
        profile('alice', 'AliceNick'),
      ),
    );
    await assertFails(
      alice.firestore().collection('publicProfiles').doc('alice').set(
        profile('alice', '   '),
      ),
    );
    await assertFails(
      alice.firestore().collection('publicProfiles').doc('alice').set(
        profile('alice', 'A'),
      ),
    );
    await assertFails(
      alice.firestore().collection('publicProfiles').doc('alice').set(
        profile('alice', 'a'.repeat(21)),
      ),
    );
    await assertFails(
      bob.firestore().collection('publicProfiles').doc('alice').set(
        profile('alice', 'Hacked'),
      ),
    );
    await assertFails(
      alice.firestore().collection('publicProfiles').doc('alice').delete(),
    );

    // --- share v1 (atomic transaction: group + post together) ---
    // Mirrors the Flutter client publish path. Rules must use getAfter/existsAfter.
    // Client also tx.get()/get() the group before it exists — read must allow missing own id.
    const channelId = 'ch_1794197482927584_8096';
    const groupId = `alice__${channelId}`;
    const groupCreatedAt = new Date('2026-01-01T00:00:00.000Z');

    // Missing own group id is readable (needed for first-publish tx.get).
    await assertSucceeds(
      alice.firestore().collection('shareGroups').doc(groupId).get(),
    );
    await assertSucceeds(
      bob.firestore().collection('shareGroups').doc(`bob__${channelId}`).get(),
    );
    // Other user's group id prefix is not readable even when missing.
    await assertFails(
      bob.firestore().collection('shareGroups').doc(groupId).get(),
    );

    await assertSucceeds(
      alice.firestore().runTransaction(async (tx) => {
        const groupRef = alice.firestore().collection('shareGroups').doc(groupId);
        const postRef = alice.firestore().collection('sharePosts').doc('post1');
        // Same order as Flutter: read group (may be missing), then write group+post.
        const existing = await tx.get(groupRef);
        if (existing.exists) {
          throw new Error('expected missing group for v1');
        }
        tx.set(groupRef, {
          ownerUid: 'alice',
          sourceChannelId: channelId,
          latestVersion: 1,
          createdAt: groupCreatedAt,
          updatedAt: new Date(),
        });
        tx.set(
          postRef,
          postPayload('alice', channelId, 1, {
            snapshot: {
              channelName: 'Shared Channel',
              isKidsChannel: false,
              playOrder: 'oldestAdded',
              coverLabel: 'CH',
              accentColor: 0xff6b4c9a,
              videos: [
                {
                  youtubeVideoId: 'abc12345678',
                  title: 'Vid',
                  manualOrder: 0,
                  thumbnailUrl: 'https://i.ytimg.com/vi/abc12345678/hqdefault.jpg',
                },
              ],
            },
          }),
        );
      }),
    );

    // Post create without group in the same request still fails.
    await assertFails(
      alice.firestore().collection('sharePosts').doc('orphan').set(
        postPayload('alice', 'ch_orphan', 1),
      ),
    );

    // Guest can read published post
    await assertSucceeds(
      guest.firestore().collection('sharePosts').doc('post1').get(),
    );

    // UID spoof / other user edit blocked
    await assertFails(
      bob.firestore().collection('shareGroups').doc(`bob__${channelId}`).set({
        ownerUid: 'alice',
        sourceChannelId: channelId,
        latestVersion: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
    await assertFails(
      bob.firestore().collection('sharePosts').doc('post1').update({
        status: 'cancelled',
        cancelledAt: new Date(),
      }),
    );
    await assertFails(
      bob.firestore().collection('sharePosts').doc('stolen').set(
        postPayload('alice', channelId, 2),
      ),
    );
    await assertFails(
      guest.firestore().collection('sharePosts').doc('g1').set(
        postPayload('alice', channelId, 2),
      ),
    );

    // Snapshot mutation blocked on cancel path
    await assertFails(
      alice.firestore().collection('sharePosts').doc('post1').update({
        status: 'cancelled',
        cancelledAt: new Date(),
        title: 'Mutated',
      }),
    );

    // Owner cancel allowed
    await assertSucceeds(
      alice.firestore().collection('sharePosts').doc('post1').update({
        status: 'cancelled',
        cancelledAt: new Date(),
      }),
    );

    // Delete blocked
    await assertFails(
      alice.firestore().collection('sharePosts').doc('post1').delete(),
    );

    // --- share v2 atomic (bump group + create post in one transaction) ---
    await assertSucceeds(
      alice.firestore().runTransaction(async (tx) => {
        const groupRef = alice.firestore().collection('shareGroups').doc(groupId);
        const postRef = alice.firestore().collection('sharePosts').doc('post2');
        tx.set(groupRef, {
          ownerUid: 'alice',
          sourceChannelId: channelId,
          latestVersion: 2,
          createdAt: groupCreatedAt,
          updatedAt: new Date(),
        });
        tx.set(
          postRef,
          postPayload('alice', channelId, 2, {
            snapshot: {
              channelName: 'Shared Channel v2',
              isKidsChannel: false,
              playOrder: 'oldestAdded',
              videos: [
                { youtubeVideoId: 'newvideo123', title: 'New', manualOrder: 0 },
              ],
            },
          }),
        );
      }),
    );

    // Version mismatch rejected
    await assertFails(
      alice.firestore().collection('sharePosts').doc('postBad').set(
        postPayload('alice', channelId, 99),
      ),
    );

    console.log('firestore rules tests: PASS');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((err) => {
  console.error('firestore rules tests: FAIL');
  console.error(err);
  process.exit(1);
});
