/*
 * SPDX-License-Identifier: Apache-2.0
 */

import { type Contract } from 'fabric-contract-api';
import { UserContract } from './contracts/userContract';

export const contracts: typeof Contract[] = [UserContract];
