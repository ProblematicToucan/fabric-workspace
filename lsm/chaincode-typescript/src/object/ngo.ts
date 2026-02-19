/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { Object, Property } from 'fabric-contract-api';

@Object()
export class NGO {
    @Property()
    public id: string = '';
    @Property()
    public name: string = '';
    @Property()
    public registrationNumber: string = '';
    @Property()
    public description?: string;
    @Property()
    public website?: string;
    @Property()
    public email?: string;
    @Property()
    public phone?: string;
    @Property()
    public address: string = '';
    @Property()
    creatorMSP: string = '';
    @Property()
    creator: string = '';
    @Property()
    createdAt: string = '';
    @Property()
    updatedAt: string = '';
    @Property()
    type: string = 'NGO';
}