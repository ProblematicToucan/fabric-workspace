/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { Object, Property } from 'fabric-contract-api';

@Object()
export class Bank {
    @Property()
    public id: string = '';
    @Property()
    public name: string = '';
    @Property()
    public bankCode: string = '';
    @Property()
    public branchCode: string = '';
    @Property()
    public creatorMSP: string = '';
    @Property()
    public creator: string = '';
    @Property()
    public createdAt: string = '';
    @Property()
    public updatedAt: string = '';
    @Property()
    public type: string = 'BANK';
}