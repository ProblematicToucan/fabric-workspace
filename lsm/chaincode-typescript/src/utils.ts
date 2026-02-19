/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { Context } from "fabric-contract-api";

export function requireMSP(ctx: Context, allowedMSPs: string[], role: string): void {
    const clientMSP = ctx.clientIdentity.getMSPID(); // get the client's MSPID
    const userRole = ctx.clientIdentity.getAttributeValue('role'); // get the user's role

    if (!allowedMSPs.includes(clientMSP)) { // check if the client's MSPID is in the allowed list
        throw new Error(`User ${clientMSP} is not authorized to perform this action`);
    }
    if (userRole !== role) { // check if the user's role is the allowed role
        throw new Error(`User ${clientMSP} is not authorized to perform this action with role ${userRole}`);
    }
}

export async function assetExists(ctx: Context, assetKey: string): Promise<boolean> {
    const assetJSON = await ctx.stub.getState(assetKey);
    return assetJSON && assetJSON.length > 0;
}

export function getTimestamp(ctx: Context): string {
    const timestamp = ctx.stub.getTxTimestamp();
    const milliseconds = Number(timestamp.seconds) * 1000 + Number(timestamp.nanos) / 1e6;
    const date = new Date(milliseconds);
    return date.toISOString();
}