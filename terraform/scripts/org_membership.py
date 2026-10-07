#!/usr/bin/env python3
"""Ensure an AWS account is a member of the caller's organization and sits in
the requested parent (root or OU).

Terraform has no resource for organization invitations/handshakes, so the
02-organization layer calls this from a terraform_data provisioner. Accounts
that are already members (always the case for the commercial partition) are
only moved.
It is idempotent and replaces the InviteAccounts Lambda and the
initialize_organizational_units pipeline Lambda of the CloudFormation version.

Credentials: the organization management account (standard AWS env/profile).
Invited accounts must trust that account through --role-name (the role
created by CreateGovCloudAccount). Works in the aws and aws-us-gov partitions.
"""

import argparse
import sys
import time

import boto3
from botocore.exceptions import ClientError


def find_member(org, account_id):
    try:
        return org.describe_account(AccountId=account_id)['Account']
    except org.exceptions.AccountNotFoundException:
        return None


def invite_and_accept(org, sts, partition, region, account_id, role_name):
    handshake = org.invite_account_to_organization(
        Target={'Id': account_id, 'Type': 'ACCOUNT'}
    )['Handshake']
    print(f'Invited {account_id} (handshake {handshake["Id"]})')

    creds = sts.assume_role(
        RoleArn=f'arn:{partition}:iam::{account_id}:role/{role_name}',
        RoleSessionName='CompliantFrameworkInstall',
    )['Credentials']
    child = boto3.client(
        'organizations',
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken'],
        region_name=region,
    )
    child.accept_handshake(HandshakeId=handshake['Id'])
    print(f'Accepted handshake in {account_id}')

    for _ in range(30):
        if find_member(org, account_id):
            return
        time.sleep(5)
    raise RuntimeError(f'{account_id} did not join the organization in time')


def ensure_parent(org, account_id, parent_id):
    current = org.list_parents(ChildId=account_id)['Parents'][0]['Id']
    if current == parent_id:
        print(f'{account_id} already in {parent_id}')
        return
    org.move_account(
        AccountId=account_id,
        SourceParentId=current,
        DestinationParentId=parent_id,
    )
    print(f'Moved {account_id} from {current} to {parent_id}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--account-id', required=True)
    parser.add_argument('--parent-id', required=True)
    parser.add_argument('--role-name', default='CompliantFrameworkAccountAccessRole')
    parser.add_argument('--region', required=True)
    args = parser.parse_args()

    session = boto3.session.Session(region_name=args.region)
    org = session.client('organizations')
    sts = session.client('sts')
    partition = sts.get_caller_identity()['Arn'].split(':')[1]

    try:
        if find_member(org, args.account_id) is None:
            invite_and_accept(org, sts, partition, args.region,
                              args.account_id, args.role_name)
        ensure_parent(org, args.account_id, args.parent_id)
    except ClientError as err:
        print(err, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
