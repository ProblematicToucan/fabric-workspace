/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * Minimal mock stub and context for unit testing chaincode without a Fabric peer.
 * Implements only the stub methods used by the LSM contracts.
 */

import type {Context} from 'fabric-contract-api';

const store = new Map<string, Uint8Array>();

export interface MockContextOptions {
    /** MSP ID for clientIdentity.getMSPID() (e.g. 'Org2MSP' for gov user). */
    mspId?: string;
    /** Role attribute for clientIdentity.getAttributeValue('role') (e.g. 'govUser'). */
    role?: string;
}

function* rangeEntries(startKey: string, endKey: string): Generator<{key: string; value: Uint8Array}> {
    const keys = Array.from(store.keys()).sort();
    for (const key of keys) {
        if (startKey !== '' && key < startKey) continue;
        if (endKey !== '' && key >= endKey) continue;
        const value = store.get(key);
        if (value !== undefined) yield {key, value};
    }
}

// Iterator yields KV objects (key, value); when exhausted, next() returns { value: undefined, done: true }.
async function* asyncRange(startKey: string, endKey: string): AsyncGenerator<{key: string; value: Uint8Array}> {
    await Promise.resolve();
    for (const entry of rangeEntries(startKey, endKey)) {
        yield entry;
    }
}

const mockStub = {
    getState: async (key: string): Promise<Uint8Array> => {
        await Promise.resolve();
        const v = store.get(key);
        return v ?? new Uint8Array(0);
    },
    putState: async (key: string, value: Uint8Array): Promise<void> => {
        await Promise.resolve();
        store.set(key, value);
    },
    deleteState: async (key: string): Promise<void> => {
        await Promise.resolve();
        store.delete(key);
    },
    getStateByRange: async (startKey: string, endKey: string) => {
        await Promise.resolve();
        const it = asyncRange(startKey, endKey);
        return {
            next: () => it.next(),
            close: async () => {},
            [Symbol.asyncIterator]: () => it,
        };
    },
    getTxTimestamp: () => ({ seconds: 1000, nanos: 0 }),
};

const mockLogging = {
    setLevel: (): void => {},
    getLogger: () => ({
        debug: () => {},
        info: () => {},
        warn: () => {},
        error: () => {},
    }),
};

function createClientIdentity(opts: MockContextOptions = {}): Context['clientIdentity'] {
    const mspId = opts.mspId ?? 'Org1MSP';
    const role = opts.role ?? '';
    return {
        getMSPID: () => mspId,
        getID: () => 'x509::mock::subject',
        getAttributeValue: (attrName: string) => (attrName === 'role' ? role : null),
    } as Context['clientIdentity'];
}

/**
 * Creates a mock Context for unit testing. Uses an in-memory store (shared across calls by default).
 * Call resetMockStubStore() between tests if you need a clean state.
 * @param opts - Optional MSP ID and role for requireMSP (e.g. { mspId: 'Org2MSP', role: 'govUser' }).
 */
export function newMockContext(opts: MockContextOptions = {}): Context {
    return {
        stub: mockStub as unknown as Context['stub'],
        clientIdentity: createClientIdentity(opts),
        logging: mockLogging as unknown as Context['logging'],
    };
}

/**
 * Clears the in-memory store used by the mock stub. Call before or after a test to isolate state.
 */
export function resetMockStubStore(): void {
    store.clear();
}
