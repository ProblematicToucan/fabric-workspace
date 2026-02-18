/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * Unit tests for AssetTransferContract. No Fabric peer or deployment required.
 */
/// <reference types="vitest/globals" />

import {AssetTransferContract} from './assetTransfer';
import type {Asset} from './asset';
import {newMockContext, resetMockStubStore} from './mockContext';

describe('AssetTransferContract', () => {
    let contract: AssetTransferContract;
    let ctx: ReturnType<typeof newMockContext>;

    beforeEach(() => {
        resetMockStubStore();
        contract = new AssetTransferContract();
        ctx = newMockContext();
    });

    describe('CreateAsset', () => {
        it('creates a new asset', async () => {
            await contract.CreateAsset(ctx, 'asset1', 'blue', 5, 'Alice', 100);
            const json = await contract.ReadAsset(ctx, 'asset1');
            const asset = JSON.parse(json) as Asset;
            expect(asset.ID).toBe('asset1');
            expect(asset.Color).toBe('blue');
            expect(asset.Size).toBe(5);
            expect(asset.Owner).toBe('Alice');
            expect(asset.AppraisedValue).toBe(100);
        });

        it('throws if asset already exists', async () => {
            await contract.CreateAsset(ctx, 'asset1', 'blue', 5, 'Alice', 100);
            await expect(contract.CreateAsset(ctx, 'asset1', 'red', 10, 'Bob', 200)).rejects.toThrow(
                /already exists/
            );
        });
    });

    describe('ReadAsset', () => {
        it('throws if asset does not exist', async () => {
            await expect(contract.ReadAsset(ctx, 'nonexistent')).rejects.toThrow(/does not exist/);
        });
    });

    describe('AssetExists', () => {
        it('returns false when asset does not exist', async () => {
            expect(await contract.AssetExists(ctx, 'id1')).toBe(false);
        });

        it('returns true after CreateAsset', async () => {
            await contract.CreateAsset(ctx, 'id1', 'green', 1, 'Owner', 50);
            expect(await contract.AssetExists(ctx, 'id1')).toBe(true);
        });
    });

    describe('UpdateAsset', () => {
        it('updates an existing asset', async () => {
            await contract.CreateAsset(ctx, 'a1', 'blue', 5, 'Alice', 100);
            await contract.UpdateAsset(ctx, 'a1', 'red', 10, 'Bob', 200);
            const json = await contract.ReadAsset(ctx, 'a1');
            const asset = JSON.parse(json) as Asset;
            expect(asset.Color).toBe('red');
            expect(asset.Size).toBe(10);
            expect(asset.Owner).toBe('Bob');
            expect(asset.AppraisedValue).toBe(200);
        });

        it('throws if asset does not exist', async () => {
            await expect(
                contract.UpdateAsset(ctx, 'missing', 'red', 1, 'X', 1)
            ).rejects.toThrow(/does not exist/);
        });
    });

    describe('DeleteAsset', () => {
        it('deletes an asset', async () => {
            await contract.CreateAsset(ctx, 'a1', 'blue', 5, 'Alice', 100);
            await contract.DeleteAsset(ctx, 'a1');
            expect(await contract.AssetExists(ctx, 'a1')).toBe(false);
            await expect(contract.ReadAsset(ctx, 'a1')).rejects.toThrow(/does not exist/);
        });

        it('throws if asset does not exist', async () => {
            await expect(contract.DeleteAsset(ctx, 'missing')).rejects.toThrow(/does not exist/);
        });
    });

    describe('TransferAsset', () => {
        it('updates owner and returns old owner', async () => {
            await contract.CreateAsset(ctx, 'a1', 'blue', 5, 'Alice', 100);
            const oldOwner = await contract.TransferAsset(ctx, 'a1', 'Bob');
            expect(oldOwner).toBe('Alice');
            const json = await contract.ReadAsset(ctx, 'a1');
            const asset = JSON.parse(json) as Asset;
            expect(asset.Owner).toBe('Bob');
        });
    });

    describe('GetAllAssets', () => {
        it('returns empty array when no assets', async () => {
            const result = await contract.GetAllAssets(ctx);
            expect(JSON.parse(result)).toEqual([]);
        });

        it('returns all created assets', async () => {
            await contract.CreateAsset(ctx, 'a1', 'blue', 1, 'A', 10);
            await contract.CreateAsset(ctx, 'a2', 'red', 2, 'B', 20);
            const result = await contract.GetAllAssets(ctx);
            const assets = JSON.parse(result) as Asset[];
            expect(assets).toHaveLength(2);
            const ids = assets.map((a) => a.ID).sort();
            expect(ids).toEqual(['a1', 'a2']);
        });
    });

    describe('InitLedger', () => {
        it('initializes sample assets', async () => {
            await contract.InitLedger(ctx);
            const result = await contract.GetAllAssets(ctx);
            const assets = JSON.parse(result) as Asset[];
            expect(assets.length).toBeGreaterThanOrEqual(6);
            const asset1 = assets.find((a) => a.ID === 'asset1');
            expect(asset1).toBeDefined();
            expect(asset1?.Owner).toBe('Tomoko');
        });
    });
});
