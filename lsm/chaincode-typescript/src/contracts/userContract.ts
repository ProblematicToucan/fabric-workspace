/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { Context, Contract, Info, Returns, Transaction } from 'fabric-contract-api';
import { NGO } from '../object/ngo';
import { assetExists, getTimestamp, requireMSP } from '../utils';
import stringify from 'json-stringify-deterministic';
import sortKeysRecursive from 'sort-keys-recursive';
import { Donor } from '../object/donor';
import { Bank } from '../object/bank';

@Info({ title: 'UserContract', description: 'Smart contract for managing users' })
export class UserContract extends Contract {
    @Transaction()
    public async RegisterNGO(ctx: Context, ngo: NGO): Promise<string> {
        ngo.creatorMSP = ctx.clientIdentity.getMSPID();
        ngo.creator = ctx.clientIdentity.getID();
        ngo.createdAt = getTimestamp(ctx);

        requireMSP(ctx, ['Org3MSP'], 'ngoAdmin'); // check if the user is a ngo admin
        const ngoKey = `ngo:${ngo.id}`;
        if (await assetExists(ctx, ngoKey)) {
            throw new Error(`NGO ${ngo.id} already exists`);
        }

        await ctx.stub.putState(ngoKey, Buffer.from(stringify(sortKeysRecursive(ngo))));
        return JSON.stringify(ngo);
    }

    @Transaction(false)
    @Returns('NGO')
    public async GetNGO(ctx: Context, id: string): Promise<NGO> {
        const ngoKey = `ngo:${id}`;
        const ngoJSON = await ctx.stub.getState(ngoKey);
        if (!ngoJSON || ngoJSON.length === 0) {
            throw new Error(`NGO ${id} does not exist`);
        }
        return JSON.parse(ngoJSON.toString());
    }

    @Transaction()
    public async UpdateNGO(ctx: Context, id: string, update: Partial<NGO>): Promise<string> {
        requireMSP(ctx, ['Org3MSP'], 'ngoAdmin'); // check if the user is a ngo admin
        const ngo = await this.GetNGO(ctx, id) as NGO;
        const updatedNGO = { ...ngo, ...update, updatedAt: getTimestamp(ctx) } as NGO;
        await ctx.stub.putState(`ngo:${id}`, Buffer.from(stringify(sortKeysRecursive(updatedNGO))));
        return JSON.stringify(updatedNGO);
    }

    @Transaction()
    public async RegisterDonor(ctx: Context, donor: Donor): Promise<string> {
        donor.creatorMSP = ctx.clientIdentity.getMSPID();
        donor.creator = ctx.clientIdentity.getID();
        donor.createdAt = getTimestamp(ctx);

        // Donor is public user, so no need to check for MSP
        const donorKey = `donor:${donor.id}`;
        if (await assetExists(ctx, donorKey)) {
            throw new Error(`Donor ${donor.id} already exists`);
        }
        await ctx.stub.putState(donorKey, Buffer.from(stringify(sortKeysRecursive(donor))));
        return JSON.stringify(donor);
    }

    @Transaction(false)
    @Returns('Donor')
    public async GetDonor(ctx: Context, id: string): Promise<Donor> {
        const donorKey = `donor:${id}`;
        const donorJSON = await ctx.stub.getState(donorKey);
        if (!donorJSON || donorJSON.length === 0) {
            throw new Error(`Donor ${id} does not exist`);
        }
        return JSON.parse(donorJSON.toString());
    }

    @Transaction()
    public async UpdateDonor(ctx: Context, id: string, update: Partial<Donor>): Promise<string> {
        const donor = await this.GetDonor(ctx, id) as Donor;
        const updatedDonor = { ...donor, ...update, updatedAt: getTimestamp(ctx) } as Donor;
        await ctx.stub.putState(`donor:${id}`, Buffer.from(stringify(sortKeysRecursive(updatedDonor))));
        return JSON.stringify(updatedDonor);
    }

    @Transaction()
    public async RegisterBank(ctx: Context, bank: Bank): Promise<string> {
        bank.creatorMSP = ctx.clientIdentity.getMSPID();
        bank.creator = ctx.clientIdentity.getID();
        bank.createdAt = getTimestamp(ctx);

        requireMSP(ctx, ['Org2MSP'], 'govUser'); // check if the user is a gov user
        const bankKey = `bank:${bank.id}`;
        if (await assetExists(ctx, bankKey)) {
            throw new Error(`Bank ${bank.id} already exists`);
        }
        await ctx.stub.putState(bankKey, Buffer.from(stringify(sortKeysRecursive(bank))));
        return JSON.stringify(bank);
    }

    @Transaction(false)
    @Returns('Bank')
    public async GetBank(ctx: Context, id: string): Promise<Bank> {
        const bankKey = `bank:${id}`;
        const bankJSON = await ctx.stub.getState(bankKey);
        if (!bankJSON || bankJSON.length === 0) {
            throw new Error(`Bank ${id} does not exist`);
        }
        return JSON.parse(bankJSON.toString());
    }

    @Transaction(false)
    @Returns('Bank[]')
    public async GetAllBanks(ctx: Context): Promise<Bank[]> {
        requireMSP(ctx, ['Org2MSP'], 'govUser'); // check if the user is a gov user
        const startKey = 'bank:';
        const endKey = 'bank;';
        const bankIterator = await ctx.stub.getStateByRange(startKey, endKey);
        const banks: Bank[] = [];
        try {
            let result = await bankIterator.next();
            while (!result.done) {
                const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
                let record: Bank | string;
                try {
                    record = JSON.parse(strValue) as Bank;
                } catch (err) {
                    console.log(err);
                    record = strValue as unknown as Bank;
                }
                banks.push(record as Bank);
                result = await bankIterator.next();
            }
            return banks;
        } finally {
            await bankIterator.close();
        }
    }

    @Transaction()
    public async UpdateBank(ctx: Context, id: string, update: Partial<Bank>): Promise<string> {
        requireMSP(ctx, ['Org2MSP'], 'govUser'); // check if the user is a gov user
        const bank = await this.GetBank(ctx, id) as Bank;
        const updatedBank = { ...bank, ...update, updatedAt: getTimestamp(ctx) } as Bank;
        await ctx.stub.putState(`bank:${id}`, Buffer.from(stringify(sortKeysRecursive(updatedBank))));
        return JSON.stringify(updatedBank);
    }

    @Transaction(false)
    @Returns('boolean')
    public async AssetExists(ctx: Context, assetType: string, id: string): Promise<boolean> {
        const assetKey = `${assetType}:${id}`;
        return await assetExists(ctx, assetKey);
    }
}