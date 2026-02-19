/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * Unit tests for UserContract. No Fabric peer or deployment required.
 */
/// <reference types="vitest/globals" />

import { UserContract } from './userContract';
import type { Bank } from '../object/bank';
import { newMockContext, resetMockStubStore } from '../mockContext';

const govContext = () => newMockContext({ mspId: 'Org2MSP', role: 'govUser' });

describe('UserContract', () => {
    let contract: UserContract;
    let ctx: ReturnType<typeof newMockContext>;

    beforeEach(() => {
        resetMockStubStore();
        contract = new UserContract();
        ctx = govContext();
    });

    describe('GetAllBanks', () => {
        it('throws when caller is not gov user (wrong MSP)', async () => {
            const nonGovCtx = newMockContext({ mspId: 'Org1MSP', role: 'govUser' });
            await expect(contract.GetAllBanks(nonGovCtx)).rejects.toThrow(/not authorized/);
        });

        it('throws when caller has wrong role', async () => {
            const wrongRoleCtx = newMockContext({ mspId: 'Org2MSP', role: 'ngoAdmin' });
            await expect(contract.GetAllBanks(wrongRoleCtx)).rejects.toThrow(/not authorized/);
        });

        it('returns empty array when no banks exist', async () => {
            const banks = await contract.GetAllBanks(ctx);
            expect(banks).toEqual([]);
        });

        it('returns all banks in range bank: to bank;', async () => {
            const bank1: Bank = {
                id: 'bank1',
                name: 'Bank One',
                bankCode: 'BO',
                branchCode: '001',
                creatorMSP: 'Org2MSP',
                creator: 'x509::...',
                createdAt: '',
                updatedAt: '',
                type: 'BANK',
            };
            const bank2: Bank = {
                id: 'bank2',
                name: 'Bank Two',
                bankCode: 'BT',
                branchCode: '002',
                creatorMSP: 'Org2MSP',
                creator: 'x509::...',
                createdAt: '',
                updatedAt: '',
                type: 'BANK',
            };
            await contract.RegisterBank(ctx, bank1);
            await contract.RegisterBank(ctx, bank2);

            const banks = await contract.GetAllBanks(ctx);
            expect(banks).toHaveLength(2);
            const ids = banks.map((b) => b.id).sort();
            expect(ids).toEqual(['bank1', 'bank2']);
            expect(banks.find((b) => b.id === 'bank1')?.name).toBe('Bank One');
            expect(banks.find((b) => b.id === 'bank2')?.name).toBe('Bank Two');
        });
    });
});
