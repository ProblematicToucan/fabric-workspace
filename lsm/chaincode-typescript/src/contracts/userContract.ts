/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { Context, Contract, Info, Returns, Transaction } from 'fabric-contract-api';
import { NGO } from '../object/ngo';
import { assetExists, getTimestamp, requireMSP } from '../utils';
import stringify from 'json-stringify-deterministic';
import sortKeysRecursive from 'sort-keys-recursive';

@Info({ title: 'UserContract', description: 'Smart contract for managing users' })
export class UserContract extends Contract {
    @Transaction()
    public async CreateNGO(ctx: Context, ngo: NGO): Promise<string> {
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
    public async ReadNGO(ctx: Context, id: string): Promise<NGO> {
        const ngoKey = `ngo:${id}`;
        const ngoJSON = await ctx.stub.getState(ngoKey);
        if (!ngoJSON || ngoJSON.length === 0) {
            throw new Error(`NGO ${id} does not exist`);
        }
        return JSON.parse(ngoJSON.toString());
    }

    @Transaction()
    public async UpdateNGO(ctx: Context, id: string, update: Partial<NGO>): Promise<string> {
        const ngo = await this.ReadNGO(ctx, id) as NGO;
        const updatedNGO = { ...ngo, ...update, updatedAt: getTimestamp(ctx) } as NGO;
        await ctx.stub.putState(`ngo:${id}`, Buffer.from(stringify(sortKeysRecursive(updatedNGO))));
        return JSON.stringify(updatedNGO);
    }

    @Transaction(false)
    @Returns('boolean')
    public async AssetExists(ctx: Context, assetType: string, id: string): Promise<boolean> {
        const assetKey = `${assetType}:${id}`;
        return await assetExists(ctx, assetKey);
    }
}