/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { Object, Property } from 'fabric-contract-api';

@Object()
export class Donor {
    @Property()
    public id: string = '';
    @Property()
    public name: string = '';
    @Property()
    public alias?: string;
    @Property()
    public email: string = '';
    @Property()
    public phone: string = '';
    @Property()
    public address?: string;
    @Property()
    public creatorMSP: string = '';
    @Property()
    public creator: string = '';
    @Property()
    public createdAt: string = '';
    @Property()
    public updatedAt: string = '';
    @Property()
    public type: string = 'DONOR';
}